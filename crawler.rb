require 'nokogiri'
require 'robots'
require './database.rb'
require 'net/http'

ROBOT_NAME = "SuperSpider"
$robots = Robots.new(ROBOT_NAME)

class URLParser
  def initialize(base, link)
    @base = base
    @link = link
  end
  
  def full_path
    part1 = URI(@base)
    begin
      part2 = URI(@link)
    rescue Exception => e
      part2 = URI(URI.encode(@link))
    end
    
    scheme = part2.scheme
    if scheme != "http" and scheme != "https" and scheme != nil
      return nil
    end
    
    url = URI::join(part1, part2).to_s
    # remove #-part of url
    url = url.split("#").first
  end
end

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
    url = URLParser.new(@task.encoded_url, url).full_path
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
    time_start = Time.now
    uri  = URI.parse(@task.encoded_url)
    http = Net::HTTP.new(uri.host, uri.port)
    path = uri.path.empty? ? "/" : uri.path
    
    http.request_get(path) do |response|
      if response["content-type"].include? "text/html"
        if response["location"].nil?
          html = response.read_body
          parser = HTMLParser.new(@task, html)
          links  = parser.links
          links.each {|link| Task.insert(URI.decode link)}
          @task.store_result(html)
        else
          url = URLParser.new(@task.encoded_url, response["location"]).full_path
          Task.insert(URI.decode(url))
        end
      end
    end
    
    @task.mark_done
    time_end = Time.now
    @time = time_end - time_start
  end
  
  def time
    @time
  end
end


if __FILE__ == $0
  loop do
    tasks = Task.sample(100)
    tasks.each do |task|
      if task.allowed?
        download = Download.new(task)
        begin
          download.run
          puts "[+] #{task.decoded_url[0...64]}  (#{download.time.round 2}s)"
        rescue Exception => e
          raise e
          puts "[-] #{task.decoded_url[0...64]}"
          puts e.message
        end
      end
    end
    puts "[*] Finished sample."
  end
end
