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
      threads = Indexer.config.threads
      (threads-1).times{ start_thread }
      start_loop
    end
    
    def start_thread
      Thread.new do
        start_loop
      end
    end
    
    def start_loop
      loop { Task.fetch.run }
    end
  end
end


if __FILE__ == $0
  indexer = Indexer::Main.new
  indexer.run
end