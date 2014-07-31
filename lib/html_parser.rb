module Crawler
  class HTMLParser
    attr_accessor :unvalidated_links, :html, :task
    
    def initialize(task, html)
      @task = task
      @html = html
    end
    
    def get_links
      @unvalidated_links = 0
      
      Class.new {
        include EM::Deferrable
        
        def initialize(html_parser)
          doc = Nokogiri::HTML(html_parser.html)
          _urls = []
          doc.xpath('//a[@href]').each do |link|
            if link['rel'] != "nofollow"
              html_parser.unvalidated_links += 1
              _urls << URLParser.new(html_parser.task.encoded_url, link['href']).full_path
            end
          end
          
          allowed_urls = []
          _urls.each do |url|
            RobotsParser.allowed?(url).callback{ |allowed|
              if allowed
                allowed_urls << url
              end
              html_parser.unvalidated_links -= 1
              if html_parser.unvalidated_links == 0
                succeed(allowed_urls)
              end
            }
          end
        end
      }.new(self)
    end
  end
end