module Crawler
  class HTMLParser
    attr_accessor :html, :base_url
    
    # base_url muss UTF8 Zeichen URL kodiert beinhalten
    def initialize(base_url, html)
      @base_url = base_url
      @html = html
    end
    
    def get_links
      doc = Nokogiri::HTML(@html)
      urls = []
      doc.xpath('//a[@href]').each do |link|
        if link['rel'] != "nofollow"
          url = URLParser.new(@base_url, link['href']).full_path
          urls << url unless url.nil?
        end
      end
      urls
    end
  end
end