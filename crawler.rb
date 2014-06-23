require 'nokogiri'
require 'robots'
require './database.rb'
require 'net/http'

ROBOT_NAME = "SuperSpider"
$robots = Robots.new(ROBOT_NAME)

class HTMLParser
  def initialize(task, html)
    @task = task
    @html = html
  end
  
  def links
    res = []
    doc = Nokogiri::HTML(@html)
    doc.xpath('//a[@href]').each do |link|
      if link['rel'] != "nofollow"
        u = _clean_url(link['href'])
        res << u unless u.nil?
      end
    end
    res
  end
  
  private
  def _clean_url(url)
    part1 = URI(@task.url)
    begin
      part2 = URI(url)
    rescue Exception => e
      part2 = URI(URI.encode(url))
    end
    
    scheme = part2.scheme
    if scheme != "http" and scheme != "https" and scheme != nil
      return nil
    end
    
    url = URI::join(@task.url, url).to_s
    
    # remove #-part of url
    url = url.split("#").first
    
    if $robots.allowed? url
      return url
    else
      return nil
    end
  end
end

class Download
  def initialize(task)
    @task = task
  end
  
  def run
    uri  = URI.parse(@task.url)
    http = Net::HTTP.new(uri.host, uri.port)
    path = uri.path.empty? ? "/" : uri.path
    
    http.request_get(path) do |response|
      if response["content-type"].include? "text/html"
        if response["ocation"].nil?
          html = response.read_body
          parser = HTMLParser.new(@task, html)
          links  = parser.links
          links.each {|link| Task.insert link}
        else
          Task.insert response["location"]
        end
      end
    end
    
    @task.mark_done
  end
end



loop do
  tasks = Task.sample(100)
  tasks.each do |task|
    if task.allowed?
      download = Download.new(task)
      begin
        download.run
        print "+"
      rescue Exception => e
        puts e.message
        print "-"
      end
    end
  end
end
