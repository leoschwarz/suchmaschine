module Crawler
  # Implementierung ähnlich der Google Spezifikation:
  # https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt

  class RobotsTXT
    def initialize(robot_name)
      @robot_name = robot_name
      @parsers    = Common::RAMCacheFIFO.new(200)
    end

    def self.instance(robot_name)
      @@instances ||= {}
      @@instances[robot_name] ||= RobotsTXT.new(robot_name)
    end

    # Deferrable, callback wird mit Rückgabewert true/false aufgerufen
    def allowed?(url)
      match  = /^http[s]?:\/\/([a-zA-Z0-9\.-]+)(.*)/.match(url)
      if match.nil? then return false end
      domain = match[1].downcase
      path   = match[2]
      if path.empty? then path = "/" end

      @parsers[domain] ||= RobotsTXTParser.new(domain, @robot_name)
      @parsers[domain].allowed?(path)
    end

    def self.allowed?(url)
      RobotsTXT.instance(Config.crawler.agent).allowed?(url)
    end
  end
end
