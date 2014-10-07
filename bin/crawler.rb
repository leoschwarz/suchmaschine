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
      Crawler.config.parallel_tasks.times{ start_thread }
      @timer = Thread.new{ loop{ sleep Crawler.config.log_interval; dump_log } }
      
      loop do 
        sleep 100
      end
    end
    
    def dump_log
      @logger.write
    end
    
    def start_thread
      Thread.new do
        loop do
          result = Task.fetch.execute
          @logger.register result
        end
      end
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
