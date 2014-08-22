module Crawler
  class RobotsTxtParser
    include EM::Deferrable
    
    attr_accessor :domain, :cache_item
    def initialize(domain, robot_name)
      @domain     = domain
      @robot_name = robot_name
      @cache_item = nil
    end
    
    def load
      if not @cache_item.nil?
        succeed
      end
      
      RobotsTxtCacheItem.for_domain(@domain).callback{|cache_item|
        @cache_item = cache_item
        if @cache_item.status == :ok
          succeed
        else
          # Download der robots.txt Datei
          url  = "http://#{@domain}/robots.txt"
          http = EventMachine::HttpRequest.new(url).get(timeout: Crawler.config.robots_txt.timeout, head: {user_agent: Crawler.config.user_agent}, redirects: 3)
          http.callback {
            c = http.response_header.http_status.to_s[0]
            
            if c == "2"              
              # Siehe: http://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
              @cache_item.rules = parse(http.response.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''))
              @cache_item.set_valid_for(:default)
            elsif c == "3" or c == "5"
              @cache_item.rules = [[:disallow, "/"]]
              @cache_item.set_valid_for(30)
            elsif c == "4"
              @cache_item.rules = []
              @cache_item.set_valid_for(:default)
            end
                    
            _save_cache_item
          }.errback{|e|
            @cache_item.rules = [[:disallow, "/"]]
            @cache_item.set_valid_for(30)
            _save_cache_item
          }
        end
      }
      self
    end
    
    def allowed?(path)
      allowed = true
      explicitely_allowed = false
      
      if @cache_item.nil?
        raise "Cache Item was not loaded."
      end
      
      @cache_item.rules.each do |rule|
        if not /^(#{rule[1]})/.match(path).nil?
          if rule[0] == :disallow
            allowed = false
          elsif rule[0] == :allow
            explicitely_allowed = true
          end
        end
      end
      
      explicitely_allowed || allowed
    end
    
    def parse(txt)
      groups = [] # items of form: [["agent1", "agent2"], [[:allow, "http://bla.example.com"], [:disallow, "http://example.com"]]]
      group_open = nil
      
      txt.lines.each do |line|
        line.gsub!(/#.*/, "")
        line.strip!
        
        match = /([-a-zA-Z]+):[ ]?(.*)$/.match(line)
        if not match.nil?
          key = match[1].strip
          value = match[2].strip
          
          if key.downcase == "user-agent"
            if group_open
              groups.last[0] << value
            else
              group_open = true
              groups << [[value],[]]
            end
          elsif key.downcase == "disallow"
            if not group_open.nil?
              group_open = false
              groups.last[1] << [:disallow, _convert_to_regex_string(value)] unless value.empty?
            end
          elsif key.downcase == "allow"
            if not group_open.nil?
              group_open = false
              groups.last[1] << [:allow, _convert_to_regex_string(value)]
            end
          end
        end
      end
      
      group_unspecified = []
      groups.each do |group|
        if group[0].include? @robot_name
          return group[1]
        elsif group[0].include? "*"
          group_unspecified = group[1]
        end
      end
      
      return group_unspecified
    end
    
    private
    def _convert_to_regex_string(value)
      s = Regexp.quote(value)
      s.gsub!("\\*", "(.*)")
      s.gsub!("\\$", "$")
      s
    end
    
    def _save_cache_item
      @cache_item.save.callback {
        succeed
      }.errback {|e|
        # Dieser Fehler tritt auf, falls zweimal nacheinander in den Cache zu schreiben versucht wird.
        # Das heisst man kann dieses Problem ignorieren, denn der Wert wurde bereits gespeichert.
        # TODO: Es ist allerdings unnötiger overhead Dateien doppelt herunterzuladen, deshalb sollte man dies überflüssig machen.
        if e.class == PG::UniqueViolation
          succeed
        else
          raise e
        end
      }
    end
  end
end