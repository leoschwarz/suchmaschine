module Crawler
  class HTMLParser
    attr_accessor :html, :task
    
    def initialize(task, html)
      @task = task
      @html = html
    end
    
    def get_links
      doc = Nokogiri::HTML(html_parser.html)
      urls = []
      doc.xpath('//a[@href]').each do |link|
        if link['rel'] != "nofollow"
          urls << URLParser.new(html_parser.task.encoded_url, link['href']).full_path
        end
      end
      urls
    end
  end
end