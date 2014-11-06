require 'lz4-ruby'

module Indexer
  class Task
    def initialize(hash, metadata)
      @hash     = hash
      @metadata = metadata
    end

    # Eine neue Aufgabe laden.
    def self.load(hash)
      metadata = Indexer::Metadata.load(hash)
      self.new(hash, metadata)
    end

    # Die Aufgabe bearbeiten.
    def run
      @metadata.word_counts.each_pair do |word, count|
        IndexingCache[word] << [@hash, count]
      end
    end
  end
end
