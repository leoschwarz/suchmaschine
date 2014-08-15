require 'benchmark'
require './bin/crawler.rb'

if Dir["cache/html/*"].length < 1000
  raise "Es müssen mindestens 1000 Webseiten im Cache sein!"
end

htmls = Dir["cache/html/*"].shuffle[0...1000].map{|path| File.read(path)}
url = "http://test.example.com/index/index.html" # etwas unschön, aber es geht jetzt nicht um URLParser sondern HTMLParser

class HTMLParser
  attr_accessor :html, :base_url
  
  # base_url muss UTF8 Zeichen URL kodiert beinhalten
  def initialize(base_url, html)
    @base_url = base_url
    @html = html
  end
  
  # Variante nokogiri einfach
  def get_links_1
    doc = Nokogiri::HTML(@html)
    urls = []
    doc.xpath('//a[@href]').each do |link|
      if link['rel'] != "nofollow"
        url = Crawler::URLParser.new(@base_url, link['href']).full_path
        urls << url unless url.nil?
      end
    end
    urls
  end
  
  # Variante nokogiri traverse
  def get_links_2
    doc = Nokogiri::HTML(@html)
    urls = []
    doc.traverse do |node|
      if node.name == "a" and node.has_attribute? "href"
        rel = node.attr("rel")
        if rel.nil? or not rel.include? "nofollow" 
          url = Crawler::URLParser.new(@base_url, node.attr("href")).full_path
          urls << url unless url.nil?
        end
      end
    end
    urls
  end
  
  # Variante ohne rel=nofollow Unterstützung
  def get_links_3
    regex = /href\s*=\s*(\"([^"]*)\"|'([^']*)'|([^'">\s]+))/im
  
    @html.scan(regex).map{|result|
      href = result[1] || result[2] || result[3]
      Crawler::URLParser.new(@base_url, href).full_path
    }
  end
end

class HTMLParser_sax < Nokogiri::XML::SAX::Document
  def initialize(base_url, html)
    @base_url = base_url
    @html     = html
    @links    = []
  end
  
  def get_links_4
    parser = Nokogiri::HTML::SAX::Parser.new(self)
    parser.parse @html
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
        if rel.nil? or not rel =~ /nofollow/
          @links << Crawler::URLParser.new(@base_url, href).full_path
        end
      end
    end
  end
end

class HTMLParser_sax2 < Nokogiri::XML::SAX::Document
  def initialize
  end
  
  def get_links_5(base_url, html)
    @base_url = base_url
    @links = []
    parser = Nokogiri::HTML::SAX::Parser.new(self)
    parser.parse html
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
        if rel.nil? or not rel =~ /nofollow/
          @links << Crawler::URLParser.new(@base_url, href).full_path
        end
      end
    end
  end
end


Benchmark.bmbm(18) do |bm|
  #bm.report("get_links_1[ 100]") { htmls[0...100].each{|html| HTMLParser.new(url, html).get_links_1} }
  #bm.report("get_links_1[1000]") { htmls[0...1000].each{|html| HTMLParser.new(url, html).get_links_1} }
  #bm.report("get_links_2[ 100]") { htmls[0...100].each{|html| HTMLParser.new(url, html).get_links_2} }
  #bm.report("get_links_2[1000]") { htmls[0...1000].each{|html| HTMLParser.new(url, html).get_links_2} }
  #bm.report("get_links_3[ 100]") { htmls[0...100].each{|html| HTMLParser.new(url, html).get_links_3} }
  #bm.report("get_links_3[1000]") { htmls[0...1000].each{|html| HTMLParser.new(url, html).get_links_3} }
  bm.report("get_links_4[ 100]") { htmls[0...100].each{|html| HTMLParser_sax.new(url, html).get_links_4} }
  bm.report("get_links_4[1000]") { htmls[0...1000].each{|html| HTMLParser_sax.new(url, html).get_links_4} }
  bm.report("get_links_5[ 100]") { parser = HTMLParser_sax2.new; htmls[0...100].each{|html| parser.get_links_5(url, html)} }
  bm.report("get_links_5[1000]") { parser = HTMLParser_sax2.new; htmls[0...1000].each{|html| parser.get_links_5(url, html)} }
end
