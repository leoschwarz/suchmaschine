module Crawler
  class HTMLParser
    attr_accessor :html, :task
    
    def initialize(task, html)
      @task = task
      @html = html
    end
    
    def get_links
      doc = Nokogiri::HTML(@html)
      urls = []
      doc.xpath('//a[@href]').each do |link|
        if link['rel'] != "nofollow"
          url = URLParser.new(@task.encoded_url, link['href']).full_path
          urls << url unless url.nil?
        end
      end
      urls
    end
  end
end