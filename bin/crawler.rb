#!/usr/bin/env ruby

require 'bundler/setup'
require 'eventmachine'
require 'em-http-request'
require 'pg/em/connection_pool'
require 'nokogiri'
require 'em-hiredis'


require './lib/crawler/crawler.rb'
require './config/config.rb'
load_configuration(Crawler, "crawler.yml")


module Crawler
  class CrawlerMain
    def initialize
      @task_queue = TaskQueue.new
    end
    
    def launch
      EventMachine.run {
        puts "#{Crawler.config.user_agent} wurde gestartet."
        @logger = Crawler::Logger.new(true)
        Crawler.config.parallel_tasks.times { do_next_task }
        EventMachine.add_periodic_timer(Crawler.config.log_interval) { dump_log }
      }
    end
    
    def dump_log
      @logger.write
    end
    
    def do_next_task
      @task_queue.fetch.callback{|task|
        task.get_state.callback{|state|
          if state == :ok
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s).callback{
              task.execute.callback {
                @logger.register :success
                EventMachine.next_tick { do_next_task }
              }.errback {
                @logger.register :failure
                EventMachine.next_tick { do_next_task }
              }
            }.errback{|e|
              raise e
            }
          elsif state == :not_ready
            @logger.register :not_ready
            EventMachine.next_tick { do_next_task }
          elsif state == :not_allowed
            task.mark_disallowed
            @logger.register :not_allowed
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
