#!/usr/bin/env ruby

require 'bundler/setup'
require 'nokogiri'
require 'redis'
require 'rocksdb'


require './lib/crawler/crawler.rb'
require './config/config.rb'
load_configuration(Crawler, "crawler.yml")

# fürs Debuggen
Thread.abort_on_exception = true


module Crawler
  class CrawlerMain
    def launch
      puts "#{Crawler.config.user_agent} wurde gestartet."
      @logger = Crawler::Logger.new(true)
      Crawler.config.parallel_tasks.times{ do_next_task }
      @timer = Thread.new{ loop{ sleep Crawler.config.log_interval; dump_log } }
      
      loop do 
        sleep 1
      end
    end
    
    def dump_log
      @logger.write
    end
    
    def do_next_task
      Thread.new do
        loop do
          task = TaskQueue.fetch_task
          state = task.get_state
          
          if state == :ok
            Database.redis.set("domain.lastvisited.#{task.domain_name}", Time.now.to_f.to_s)
            if task.execute
              @logger.register :success
            else
              @logger.register :failure
            end
          elsif state == :not_ready
            @logger.register :not_ready
          elsif state == :not_allowed
            task.mark_disallowed
            @logger.register :not_allowed
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
