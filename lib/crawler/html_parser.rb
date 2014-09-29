# TODO: Effizienzoptimierung + Tests

module Crawler
  class HTMLParser
    attr_reader :indexing_allowed, :following_allowed, :links, :text
    
    def initialize(base_url, html)
      @base_url = base_url.encoded_url
      @doc      = Nokogiri::HTML(@html, nil, "UTF-8")
      
      parse()
    end
    
    def parse
      # Standardwerte
      @indexing_allowed  = true
      @following_allowed = true
      @links = []
      @text  = ""
      
      # 'robots' Meta-Tag
      # TODO: Varianten der Gross- und Kleinschreibung im XPath
      meta_robots_tag = @doc.at_xpath("//meta[@name='robots']/@content")
      unless meta_robots_tag.nil?
        meta_robots = meta_robots.text.downcase
        if meta_robots.include? "noindex"
          @indexing_allowed  = false
        elsif meta_robots.include? "nofollow"
          @following_allowed = false
        end
      end
      
      # Links
      if @following_allowed
        @doc.xpath('//a[@href]').each do |link|
          if not link['rel'].include? "nofollow"
            url = URLParser.new(@base_url, link['href']).full_path
            unless url.nil?
              @links << [link.text, url]
            end
          end
        end
      end
      
      # Text
      if @indexing_allowed
        @doc.search("script").each{|el| el.unlink}
        @doc.search("style").each{|el| el.unlink}
        @doc.xpath("//comment()").remove
        @text = @doc.text.gsub(/\s+/, " ").strip
      end
    end
  end
end
