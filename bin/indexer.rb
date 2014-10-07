#!/usr/bin/env ruby
require 'bundler/setup'
require_relative '../lib/common/common.rb'
require_relative '../lib/indexer/indexer.rb'

Common::load_configuration(Indexer, "indexer.yml")

# fürs Debuggen
Thread.abort_on_exception = true

module Indexer
  include Common::DatabaseClient
  
  class Main
    def run
      Indexer.config.threads.times{ start_thread }
      
      loop do
        # Haupt-Thread "beschäftigen"
        sleep 100
      end
    end
    
    def start_thread
      Thread.new do
        loop do
          docinfo_hash = Indexer::Database.index_queue_fetch
          docinfo      = Indexer::DocumentInfo.load(docinfo_hash)
          doc          = Indexer::Document.load(docinfo.document_hash)
          text         = doc.text
          words        = text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ").uniq
      
          Indexer::Database.index_append(words.map{|word| [word, doc.hash]})
        end
      end
    end
  end
end


if __FILE__ == $0
  indexer = Indexer::Main.new
  indexer.run
end