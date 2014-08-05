module Crawler
  # Implementierung ähnlich der Google Spezifikation:
  # https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt
  
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
          parser.domains[domain].load.callback{
            succeed parser.domains[domain].allowed?(path)
          }
        end
      }.new(self, url)
    end
    
    def self.allowed?(url)
      RobotsParser.instance(Crawler.config.user_agent).allowed?(url)
    end
  end
end