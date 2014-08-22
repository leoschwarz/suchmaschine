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
require './lib/download.rb'
require './lib/task.rb'
require './lib/task_queue.rb'
require './lib/robots_txt_cache_item.rb'
require './lib/robots_txt_parser.rb'
require './lib/robots_parser.rb'
require './lib/url_parser.rb'
require './lib/html_parser.rb'


module Crawler
  class CrawlerMain
    def initialize
      @task_queue = TaskQueue.new
    end
    
    def launch
      EventMachine.run {
        puts "#{Crawler.config.user_agent} wurde gestartet."
        Crawler.config.parallel_tasks.times { do_next_task }
      }
    end
    
    def do_next_task
      @task_queue.fetch.callback{|task|
        task.get_state.callback{|state|
          if state == :ok
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s).callback{
              task.execute.callback {
                puts "[+] #{task.decoded_url}"
                EventMachine.next_tick { do_next_task }
              }.errback {
                puts "[-] #{task.decoded_url}"
                EventMachine.next_tick { do_next_task }
              }
            }.errback{|e|
              raise e
            }
          elsif state == :not_ready
            EventMachine.next_tick { do_next_task }
          elsif state == :not_allowed
            task.mark_disallowed
            EventMachine.next_tick { do_next_task }
          end 
        }
      }
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
