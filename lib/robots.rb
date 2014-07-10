require 'json'
require 'date'
require 'net/http'

ROBOTSTXT_REQ_TIMEOUT = 0.5 # seconds
ROBOTSTXT_MAX_AGE = 1.0 # days

# Implementierung ähnlich der Google Spezifikation:
# https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt

class RobotsTxtParser
  def initialize(domain, robot_name)
    @domain     = domain
    @rules      = nil
    @robot_name = robot_name
  end
  
  def load_if_needed
    if @rules.nil?
      # 1. Cachetabelle überprüfen
      res = $db.exec_params("SELECT data, time FROM robotstxt WHERE domain = $1", [@domain])
      type = :insert
      if res.ntuples == 1
        time = DateTime.parse res.getvalue(0,1)
        if time + ROBOTSTXT_MAX_AGE < DateTime.now
          # Leider ist der Eintrag zu alt, er wird deshalb also aktualisiert werden müssen
          type = :update
        else
          # Cache hit
          load(res.getvalue(0,0))
          return
        end
      end
      
      # 2. Request starten
      uri = URI("http://#{@domain}/robots.txt")
      response = Net::HTTP.get_response(uri)
      
      # 3. Request code überprüfen
      c = response.code[0]
      if c == "2"
        _parse(response.body.force_encoding('UTF-8'))
        return save(type)
      elsif c == "3" or c == "5" # TODO: Follow up to 5 redirects.
        @rules = [[:disallow, "/"]] # alles verbieten
        return save(type)
      elsif c == "4"
        @rules = [] # alles erlauben
        return save(type)
      end
    end
  end
  
  def allowed?(path)
    load_if_needed
    
    allowed = true    
    @rules.each do |rule|
      if rule[0] == :disallow
        if not /^#{rule[1]}/.match(path).nil?
          allowed = false
        end
      elsif rule[0] == :allow
        if not /^#{rule[1]}/.match(path).nil?
          return true
        end
      end
    end
    
    return allowed
  end
  
  def serialize
    JSON.dump(@rules)
  end
  
  def load(raw)
    @rules = JSON.load(raw).map{|rule| [rule[0].to_sym, rule[1]]}
  end
  
  def save(type=:insert)
    data = self.serialize
    if type == :insert
      sql = "INSERT INTO robotstxt (domain,data,time) VALUES ($1, $2, $3)"
    elsif type == :update
      sql = "UPDATE robotstxt SET data = $2, time = $3 WHERE domain = $1"
    else
      raise "Unsupported type: #{type}"
    end
    
    $db.exec_params(sql, [@domain, data, DateTime.now])
  end
  
  private
  def _parse(txt)
    groups = [] # items of form: [["agent1", "agent2"], [[:allow, "http://bla.example.com"], [:disallow, "http://example.com"]]]
    group_open = nil
    txt.lines.each do |line|
      line.gsub!(/#.*/, "")
      line.strip!
      
      match = /([-a-zA-Z]+):[ ]?(.*)$/.match(line)
      if not match.nil?
        key = match[1]
        value = match[2]
        
        if key == "User-agent"
          if group_open
            groups.last[0] << value
          else
            group_open = true
            groups << [[value],[]]
          end
        elsif key == "Disallow"
          if not group_open.nil?
            group_open = false
            groups.last[1] << [:disallow, value] unless value.empty?
          end
        elsif key == "Allow"
          if not group_open.nil?
            group_open = false
            groups.last[1] << [:allow, value]
          end
        end
      end
    end
    
    group_unspecified = []
    
    groups.each do |group|
      if group[0].include? @robot_name
        @rules = group[1]
        return
      elsif group[0].include? "*"
        group_unspecified = group[1]
      end
    end
    
    @rules = group_unspecified
  end
end

class RobotsParser
  def initialize(robot_name)
    @robot_name = robot_name
    @domains    = {}
  end
  
  def allowed?(url)
    match  = /^http[s]?:\/\/([a-zA-Z0-9\.-]+)(.*)/.match(url)
    if match.nil? then return false end
    domain = match[1].downcase
    path   = match[2]
    if path.empty? then path = "/" end
    
    if @domains[domain].nil?
      @domains[domain] = RobotsTxtParser.new(domain, @robot_name)
    end
    @domains[domain].allowed?(path)
  end
end