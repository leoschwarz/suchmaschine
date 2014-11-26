module Crawler
  # Implementierung ähnlich der Google Spezifikation:
  # https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt
  
  # TODO: RobotsTXT ist der letzte Teil im Crawler der noch überarbeitet werden muss...

  class RobotsTXT
    def initialize(robot_name)
      @robot_name = robot_name
      @parsers    = Common::RAMCacheFIFO.new(200)
    end

    def self.instance(robot_name)
      @@instances ||= {}
      @@instances[robot_name] ||= RobotsTXT.new(robot_name)
    end

    def allowed?(url)
      domain, path = url.domain, url.path
      return false if domain.nil? || path.nil?

      @parsers[domain] ||= RobotsTXTParser.new(domain, @robot_name)
      @parsers[domain].allowed?(path)
    end

    def self.allowed?(url)
      RobotsTXT.instance(Config.crawler.agent).allowed?(url)
    end
  end
end
