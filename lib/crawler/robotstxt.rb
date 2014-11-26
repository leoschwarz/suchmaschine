module Crawler
  # Implementierung ähnlich der Google Spezifikation:
  # https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt
  class Robotstxt
    def initialize
      @parsers = Common::RAMCacheFIFO.new(200)
    end

    def self.instance
      @instance ||= self.new
    end

    # Überprüft ob es erlaubt ist auf die URL zuzugreifen.
    # @param url [URL] Die zu überprüfende URL.
    # @return [Boolean]
    def allowed?(url)
      domain, path = url.domain, url.path
      return false if domain.nil? || path.nil?

      @parsers[domain] ||= RobotstxtParser.for_domain(domain)
      @parsers[domain].allowed?(path)
    end

    def self.allowed?(url)
      self.instance.allowed?(url)
    end
  end
end
