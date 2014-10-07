#!/usr/bin/env ruby

require 'bundler/setup'
require 'nokogiri'
require 'curb'

require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'


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
          task = Task.new(Crawler::Database.download_queue_fetch)
          result = task.execute
          @logger.register result
        end
      end
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
