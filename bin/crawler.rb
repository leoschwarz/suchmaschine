#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/crawler/crawler.rb'

module Crawler
  def self.launch
    puts "#{Crawler.config.user_agent} wurde gestartet."

    @logger = Common::Logger.new({labels: {success: :Erfolge, failure: :Fehler, not_allowed: :Verboten}})
    @logger.progress[:success] = 0
    @logger.progress[:failure] = 0
    @logger.progress[:not_allowed] = 0
    
    @logger.add_output($stdout, Common::Logger::INFO)

    Crawler.config.parallel_tasks.times{ self.launch_thread }

    @logger.log_progress_labels
    loop do
      @logger.log_progress
      sleep 5
    end
  end

  def self.launch_thread
    Thread.new do
      loop do
        begin
          result_type = Task.fetch.execute
          @logger.progress[result_type] += 1
        rescue => e
          @logger.log_exception(e)
        end
      end
    end
  end
end

if __FILE__ == $0
  Crawler.launch
end
