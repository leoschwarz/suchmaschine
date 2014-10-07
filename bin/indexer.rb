#!/usr/bin/env ruby
require 'bundler/setup'
require_relative '../lib/common/common.rb'
require_relative '../lib/indexer/indexer.rb'

Common::load_configuration(Indexer, "indexer.yml")

module Indexer
  include Common::DatabaseClient
  
  class Main
    def run
      10.times{ start_thread }
    end
    
    def start_thread
      Thread.new do
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


if __FILE__ == $0
  indexer = Indexer::Main.new
  indexer.run
end