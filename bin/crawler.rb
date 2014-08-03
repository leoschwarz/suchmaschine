#!/usr/bin/env ruby

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
  class Crawler
    def initialize
      @tasks = Queue.new
      @loading_new_tasks = false
    end
    
    def launch
      puts "#{USER_AGENT} wurde gestartet."
    
      EventMachine.run {
        # Warteschlange mit Aufgaben befüllen
        Task.sample(TASK_QUEUE_SIZE).callback { |tasks|
          tasks.each {|task| @tasks << task}
          
          # Timer, der dafür zu sorgen hat, dass die Warteschlange immer genug Aufgaben enthält.
          EventMachine.add_periodic_timer(1) {
            unless @loading_new_tasks
              # Sobald weniger als 50% der maximal Anzahl an Aufgaben vorhanden ist, werden neue geladen.
              if @tasks.length < TASK_QUEUE_SIZE / 2
                @loading_new_tasks = true
                Task.sample(TASK_QUEUE_SIZE).callback { |tasks|
                  tasks.each {|task| @tasks << task}
                  @loading_new_tasks = false
                }
              end
            end
          }
          
          # Start des Crawlens
          PARALLEL_TASKS.times { do_next_task }
        }
      }
    end
    
    def do_next_task
      task = @tasks.pop
      
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
              
              do_next_task
            }
          else
            url = URLParser.new(task.encoded_url, header["location"]).full_path
            Task.insert(URI.decode(url))

            do_next_task
          end
        end
      
        puts "[+] #{task.decoded_url}"
      }
      http_request.errback {|e|
        puts "[-] #{task.decoded_url}"
        puts e.error
        
        do_next_task
      }
    end
  end
end

if __FILE__ == $0
  Crawler::Crawler.new.launch
end
