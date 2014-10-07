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
      @logger.set(:time, proc{|logger| Time.now.to_i - logger.started_at.to_i})
      
      Crawler.config.parallel_tasks.times{ start_thread }
      @logger.start_display($stdout, false)
    end
    
    def start_thread
      Thread.new do
        loop do
          sleep 10
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
