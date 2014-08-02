require 'json'
require 'date'

# Implementierung ähnlich der Google Spezifikation:
# https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt

# TODO: Diesen Parser sollte man testen, damit der Crawler nacher nicht auf irgendwelchen Webseiten unheil anstellt.
# TODO: Ausserdem gibt's hier wahrscheinlich auch noch Optimierungspotential (zum Beispiel die Serialisierung in JSON ist zwar praktisch und übersichtlich, aber ziemlich sicher nicht unglaublich schnell)

module Crawler
  class RobotsTxtCacheItem
    def initialize(data, time)
      @data = data
      @time = time
    end
    
    # Überprüft ob der Cache-Eintrag noch immer gültig ist
    def valid?
      @time + Rational(Crawler.config.robots_txt.cache_duration, 86400) > DateTime.now
    end
    
    # Sucht nach einem robots.txt Cache-Eintrag für eine bestimmte Domain.
    # Gibt ein Deferrable zurück, falls ein noch gültiger Cacheintrag gefunden wird, wird dieser als Erfolg zurück gegeben, falls dieser bereits ungültig wurde wird ein Fehler mit :outdated und falls gar keiner vorhanden ist mit :none aufgerufen.
    def self.for_domain(domain)
      Class.new {
        include EM::Deferrable
        
        def initialize(domain)
          Database.select(:robotstxt, {domain: domain}, [:data, :time]).callback{ |result|
            if result.ntuples == 1
              data = result[0]["data"]
              time = DateTime.parse(result[0]["time"])
              
              item = RobotsTxtCacheItem.new(data, time)
              if item.valid?
                succeed(item)
              else
                fail(:outdated)
              end
            else
              fail(:none)
            end
          }
        end
      }.new(domain)
    end
  end
  
  
  class RobotsTxtParser
    attr_accessor :domain, :rules
    
    def initialize(domain, robot_name)
      @domain     = domain
      @rules      = nil
      @robot_name = robot_name
    end
  
    # Nach dem Callback ist sichergestellt, dass die robots.txt Datei geladen ist.
    def load_if_needed
      Class.new {
        include EM::Deferrable
        
        def initialize(parser)
          # Falls die Regeln bereits geladen sind, ist hier schon Schluss.
          if not parser.rules.nil?
            return succeed()
          end
          
          # Cache überprüfen
          RobotsTxtCacheItem.for_domain(parser.domain).callback{ |cache_item|
            # Cachehit
            succeed parser.load_cache(cache_item.data)
          }.errback{ |cache_item|
            # Download der robots.txt Datei
            url  = "http://#{parser.domain}/robots.txt"
            http = EventMachine::HttpRequest.new(url).get(timeout: 10)
            http.callback {
              save_type = (cache_item == :outdated) ? :update : :insert
              c = http.response_header.http_status
              
              if c == "2"
                parser.parse(http.response.force_encoding('UTF-8'))                
              elsif c == "3" or c == "5" # TODO: Follow up to 5 redirects.
                parser.rules = [[:disallow, "/"]] # alles verbieten
              elsif c == "4"
                parser.rules = [] # alles erlauben
              end
              
              parser.save(save_type).callback {
                succeed
              }
            }
          }
        end
      }.new(self)
    end
  
    # Diese Funktion gibt ein Deferrable zurück, welches mit dem Rückgabe wert (bool) aufgerufen wird, der auskunft darüber gibt ob ein bestimmter Pfad zulässig ist.
    def allowed?(path)
      Class.new {
        include EM::Deferrable
        
        def initialize(parser, path)
          parser.load_if_needed.callback{
            allowed = true
            @rules.each do |rule|
              if rule[0] == :disallow
                if not /^#{rule[1]}/.match(path).nil?
                  allowed = false
                end
              elsif rule[0] == :allow
                if not /^#{rule[1]}/.match(path).nil?
                  succeed(true)
                  return
                end
              end
            end
            
            succeed(allowed)
          }
        end
      }.new(self, path)
    end
  
    def serialize
      JSON.dump(@rules)
    end
  
    def load_cache(raw)
      @rules = JSON.load(raw).map{|rule| [rule[0].to_sym, rule[1]]}
    end
  
    def save(type=:insert)
      data = self.serialize
      if type == :insert
        return Database.insert(:robotstxt, {domain: @domain, data: data, time: DateTime.now})
      elsif type == :update
        return Database.update(:robotstxt, {domain: @domain}, {data: data, time: DateTime.now})
      else
        raise "Unsupported type: #{type}"
      end
    end
    
    def parse(txt)
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
    attr_accessor :robot_name, :domains
    
    def initialize(robot_name)
      @robot_name = robot_name
      @domains    = {}
    end
    
    def self.instance(robot_name)
      @@instances ||= {}
      @@instances[robot_name] ||= RobotsParser.new(robot_name)
    end
    
    # Deferrable, callback wird mit Rückgabewert true/false aufgerufen
    def allowed?(url)
      Class.new {
        include EM::Deferrable
        def initialize(parser, url)
          match  = /^http[s]?:\/\/([a-zA-Z0-9\.-]+)(.*)/.match(url)
          if match.nil? then return succeed(false) end
          domain = match[1].downcase
          path   = match[2]
          if path.empty? then path = "/" end
          
          if parser.domains[domain].nil?
            parser.domains[domain] = RobotsTxtParser.new(domain, parser.robot_name)
          end
          
          parser.domains[domain].allowed?(path).callback{|value|
            succeed(value)
          }
        end
      }.new(self, url)
    end
    
    def self.allowed?(url)
      RobotsParser.instance(Crawler.config.user_agent).allowed?(url)
    end
  end
end