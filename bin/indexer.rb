#!/usr/bin/env ruby
require 'bundler/setup'
require_relative '../lib/common/common.rb'
require_relative '../lib/indexer/indexer.rb'

Common::load_configuration(Indexer, "indexer.yml")

# fürs Debuggen
Thread.abort_on_exception = true

module Indexer
  class Main
    def run
      @logger = Common::Logger.new(
        {
          variables: [:time, :tasks, :tasks_per_second],
          labels: {time: "Zeit", tasks: "Aufgaben", tasks_per_second: "Aufgaben/Sekunde"}
        }
      )
      @logger.add_output($stdout)
      @logger.set(:time, proc{|logger| logger.elapsed_time})
      @logger.set(:tasks_per_second, proc{|logger| (logger.get(:tasks)*1.0 / (logger.elapsed_time+0.0001)).round(2)})

      Indexer.config.threads.times{ start_thread }

      @logger.display_header
      loop do
        @logger.display_values
        sleep 5
      end
    end

    def start_thread
      Thread.new do
        start_loop
      end
    end

    def start_loop
      loop do
        begin
          Task.fetch.run
          @logger.increase(:tasks)
        rescue => error
          @logger.error(error.to_s)
        end
      end
    end
  end
end


if __FILE__ == $0
  indexer = Indexer::Main.new
  indexer.run
end
