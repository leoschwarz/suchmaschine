#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/common/common.rb'
require_relative '../lib/indexer/indexer.rb'

require 'lz4-ruby'
require 'oj'

Common::load_configuration(Indexer, "indexer.yml")

module Indexer
  class Main
    def run
      # TODO Das ist alles nur provisorisch
      docinfo_id = Database.queue_fetch
      doc_hash   = Oj.load(LZ4.uncompress(File.read("/mnt/sdb/suchmaschine/docinfo:#{docinfo_id}")))[:document_hash]
      text       = Oj.load(LZ4.uncompress(File.read("db/keyval/doc:#{doc_hash}")))[:text]
      
      ngrams     = Common::NGram.count_ngrams(text, 5)
      puts ngrams.inspect
    end
  end
end


if __FILE__ == $0
  indexer = Indexer::Main.new
  indexer.run
end