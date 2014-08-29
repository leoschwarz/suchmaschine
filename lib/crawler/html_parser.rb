module Crawler
  class HTMLParser < Nokogiri::XML::SAX::Document    
    # base_url muss UTF8 Zeichen URL kodiert beinhalten
    def initialize(base_url, html)
      @base_url = base_url
      @html = html
      @links = []
    end
    
    # Alternative Implementierungen: test/benchmark/html_parser.rb 
    def get_links
      parser = Nokogiri::HTML::SAX::Parser.new(self)
      parser.parse @html
      @links
    end
    
    def start_element name, attributes = []
      if name == "a"
        href = nil
        rel  = nil
        attributes.each do |attr|
          if attr[0] == "href"
            href = attr[1]
          elsif attr[0] == "rel"
            rel = attr[1]
          end
        end
      
        if not href.nil?
          rel = rel.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless rel.nil?
          if rel.nil? or not rel =~ /nofollow/
            link = Crawler::URLParser.new(@base_url, href).full_path
            @links << link if not (link.nil? or @links.include? link)
          end
        end
      end
    end
  end
end
