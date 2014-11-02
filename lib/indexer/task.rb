require 'lz4-ruby'

module Indexer
  class Task
    def initialize(hash, metadata)
      @hash     = hash
      @metadata = metadata
    end

    # Eine neue Aufgabe laden.
    def self.load(hash)
      metadata = Indexer::Metadata.deserialize(LZ4.uncompress(File.read(Config.paths.metadata + hash)))
      self.new(hash, metadata)
    end

    # Die Aufgabe bearbeiten.
    def run
      @metadata.word_counts.each_pair do |word, count|
        postings_tmp(word).write_entries([[@hash, count]])
      end
    end
    
    private
    def postings_tmp(word)
      Common::PostingsFile.new(File.join(Config.paths.index_tmp, "word:#{word}"), true)
    end
  end
end
