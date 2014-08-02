require 'eventmachine'
require 'em-http-request'
require 'pg/em/connection_pool'
require 'nokogiri'

require './config/config.rb'
require './lib/database.rb'
require './lib/domain.rb'
require './lib/task.rb'
require './lib/robots.rb'
require './lib/url_parser.rb'
require './lib/html_parser.rb'


module Crawler
  def self.run_task
    Task.fetch.callback { |task|
      http_request = EventMachine::HttpRequest.new(task.encoded_url).get(timeout: 10)
      http_request.callback {
        header = http_request.response_header
        
        if header["content-type"].include? "text/html"
          if header["location"].nil?
            html = http_request.response
            parser = HTMLParser.new(task, html)
            parser.get_links.callback { |links|
              links.each {|link| Task.insert(URI.decode link)}
              task.store_result(html)
              
              Crawler::run_task
            }
          else
            url = URLParser.new(task.encoded_url, header["location"]).full_path
            Task.insert(URI.decode(url))

            Crawler::run_task
          end
        end
      
        puts "[+] #{task.decoded_url}"
      }
      http_request.errback {
        puts "[-] #{task.decoded_url}"
      }
    }    
  end
  
  def self.launch
    puts "#{config.user_agent} wurde gestartet."
    
    EventMachine.run {
      10.times {
        Crawler::run_task()
      } 
    }
  end
end

if __FILE__ == $0
  Crawler::launch
end
