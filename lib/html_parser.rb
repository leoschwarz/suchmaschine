module Crawler
  class HTMLParser
    attr_accessor :unvalidated_links, :html, :task
    
    def initialize(task, html)
      @task = task
      @html = html
    end
    
    def get_links
      Class.new {
        include EM::Deferrable
        
        def initialize(html_parser)
          # alle URLs aus dem HTML extrahieren
          doc = Nokogiri::HTML(html_parser.html)
          @_urls = []
          doc.xpath('//a[@href]').each do |link|
            if link['rel'] != "nofollow"
              @_urls << URLParser.new(html_parser.task.encoded_url, link['href']).full_path
            end
          end
          
          # die erlaubten bestimmen
          @urls = []
          check_link
        end
        
        def check_link
          if @_urls.length == 0
            succeed(@urls)
            return
          end
          
          url = @_urls.pop
          RobotsParser.allowed?(url).callback{ |allowed|
            if allowed
              @urls << url
            end
            
            # nächster Link
            check_link
          }
        end
      }.new(self)
    end
  end
end