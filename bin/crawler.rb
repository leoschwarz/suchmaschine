#!/usr/bin/env ruby

require 'bundler/setup'
require 'eventmachine'
require 'em-http-request'
require 'pg/em/connection_pool'
require 'nokogiri'
require 'em-hiredis'

require './config/config.rb'
require './lib/database.rb'
require './lib/domain.rb'
require './lib/task.rb'
require './lib/robots_txt_cache_item.rb'
require './lib/robots_txt_parser.rb'
require './lib/robots_parser.rb'
require './lib/url_parser.rb'
require './lib/html_parser.rb'


module Crawler
  class CrawlerMain
    def initialize
      @tasks = Array.new
      @loading_new_tasks = false
      @domain_request_count = {}
    end
    
    def launch
      puts "#{Crawler.config.user_agent} wurde gestartet."
    
      EventMachine.run {
        # Warteschlange mit Aufgaben befüllen
        Task.sample(Crawler.config.task_queue_size).callback { |tasks|
          tasks.each {|task| @tasks << task}
          
          # Timer, der dafür zu sorgen hat, dass die Warteschlange immer genug Aufgaben enthält.
          EventMachine.add_periodic_timer(1) {
            update_queue
          }
          
          # Start des Crawlens
          Crawler.config.parallel_tasks.times { do_next_task }
        }
      }
    end
    
    def update_queue
      unless @loading_new_tasks
        # Sobald weniger als 50% der maximal Anzahl an Aufgaben vorhanden ist, werden neue geladen.
        if @tasks.length < Crawler.config.task_queue_size / 2
          # Aufgaben laden
          @loading_new_tasks = true
          Task.sample(Crawler.config.task_queue_size).callback { |tasks|
            tasks.each {|task| @tasks << task}
            @loading_new_tasks = false
          }
        end
      end
    end
    
    def do_next_task
      task = @tasks.shift
      task.get_state.callback{|state|
        if state == :ok
          Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s)
          http_request = EventMachine::HttpRequest.new(task.encoded_url).get(timeout: 10, head: {user_agent: Crawler.config.user_agent})
          http_request.callback {
            header = http_request.response_header
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s)
            if header["content-type"].include? "text/html"
              if header["location"].nil?
                html = http_request.response
                links = HTMLParser.new(task, html).get_links
                links.each {|link| Task.insert(URI.decode link)}
                task.store_result(html)
            
                puts "[+] #{task.decoded_url}"
                EventMachine.next_tick { do_next_task }
              else
                url = URLParser.new(task.encoded_url, header["location"]).full_path
                Task.insert(URI.decode(url))
                task.mark_done

                puts "[+] #{task.decoded_url}"
                EventMachine.next_tick { do_next_task }
              end
            end
          }
          http_request.errback {
            puts "[-] #{task.decoded_url}"
            EventMachine.next_tick { do_next_task }
          }
        elsif state == :not_ready
          EventMachine.next_tick { do_next_task }
        elsif state == :not_allowed
          task.mark_disallowed
          EventMachine.next_tick { do_next_task }
        end 
      }
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
