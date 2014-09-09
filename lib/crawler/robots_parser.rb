module Crawler
  # Implementierung ähnlich der Google Spezifikation:
  # https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt
  
  class RobotsParser    
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
      match  = /^http[s]?:\/\/([a-zA-Z0-9\.-]+)(.*)/.match(url)
      if match.nil? then return false end
      domain = match[1].downcase
      path   = match[2]
      if path.empty? then path = "/" end
      
      if @domains[domain].nil?
        @domains[domain] = RobotsTxtParser.new(domain, @robot_name)
      end
      @domains[domain].load.callback{
        succeed @domains[domain].allowed?(path)
      }
    end
    
    def self.allowed?(url)
      RobotsParser.instance(Crawler.config.user_agent).allowed?(url)
    end
  end
end