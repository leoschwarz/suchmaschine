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
      
      @logger = Common::Logger.new({
        variables: [:time, :success, :failure, :not_allowed],
        labels: {time: :Zeit, success: :Erfolge, failure: :Fehler, not_allowed: :Verboten}})
      @logger.set(:time, proc{|logger| logger.elapsed_time})
      @logger.add_output($stdout)
      @logger.display_header
      
      Crawler.config.parallel_tasks.times{ start_thread }
      
      loop do
        @logger.display_values
        sleep 5
      end
    end
    
    def start_thread
      Thread.new do
        loop do
          begin
            result_type = Task.fetch.execute
            @logger.increase result_type
          rescue => error
            @logger.error error.to_s
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Crawler::CrawlerMain.new.launch
end
