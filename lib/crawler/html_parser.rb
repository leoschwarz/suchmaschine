require 'nokogiri'
# TODO: Effizienzoptimierung + Tests

module Crawler
  class HTMLParser
    attr_reader :links, :text, :title

    def initialize(base_url, html)
      @base_url = base_url
      @doc      = Nokogiri::HTML(html)

      parse()
    end
    
    def permissions
      {index: @indexing_allowed, follow: @following_allowed}
    end

    def parse
      # Standardwerte
      @indexing_allowed  = true
      @following_allowed = true
      @links = []
      @text  = ""
      @title = ""

      # 'robots' Meta-Tag
      # TODO: Varianten der Gross- und Kleinschreibung im XPath
      meta_robots_tag = @doc.at_xpath("//meta[@name='robots']/@content")
      unless meta_robots_tag.nil?
        meta_robots = meta_robots_tag.text.downcase
        if meta_robots.include? "noindex"
          @indexing_allowed  = false
        end
        if meta_robots.include? "nofollow"
          @following_allowed = false
        end
      end

      # Links
      if @following_allowed
        @doc.xpath('//a[@href]').each do |link|
          if link['rel'].nil? or not link['rel'].include? "nofollow"
            url = @base_url.join_with(link['href'])
            unless url.nil?
              @links << [_clean_text(link.text), url]
            end
          end
        end
      end

      # Text
      if @indexing_allowed
        @doc.search("script").each{|el| el.unlink}
        @doc.search("style").each{|el| el.unlink}
        @doc.xpath("//comment()").remove
        @text = _clean_text(@doc.text)
      end

      # Titel
      title_tag = @doc.xpath("//title")[0]
      @title = title_tag.text unless title_tag.nil?
    end

    private
    def _clean_text(text)
      text.gsub(/\s+/, " ").strip
    end
  end
end
