module Crawler
  class HTMLParser
    attr_accessor :html, :base_url
    
    # base_url muss UTF8 Zeichen URL kodiert beinhalten
    def initialize(base_url, html)
      @base_url = base_url
      @html = html
    end
    
    # Variante nokogiri einfach
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
    
    # Variante nokogiri traverse
    #def get_links_2
    #  doc = Nokogiri::HTML(@html)
    #  urls = []
    #  doc.traverse do |node|
    #    if node.name == "a" and node.has_attribute? "href"
    #      rel = node.attr("rel")
    #      if rel.nil? or not rel.include? "nofollow" 
    #        url = URLParser.new(@base_url, node.attr("href")).full_path
    #        urls << url unless url.nil?
    #      end
    #    end
    #  end
    #  urls
    #end
    
    # Variante ohne rel=nofollow Unterstützung
    #def get_links_3
    #  regex = /href\s*=\s*(\"([^"]*)\"|'([^']*)'|([^'">\s]+))/im
    #  
    #  @html.scan(regex).map{|result|
    #    href = result[1] || result[2] || result[3]
    #    URLParser.new(@base_url, href).full_path
    #  }
    #end
    
    
  end
end