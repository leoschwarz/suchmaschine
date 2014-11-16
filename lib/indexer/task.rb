# TODO: Diese Datei noch sinnvol umbenennen...

module Indexer
  class Task
    def initialize(hash, metadata)
      @hash     = hash
      @metadata = metadata
    end

    # Eine neue Aufgabe laden.
    def self.load(hash)
      metadata = Indexer::Metadata.fetch(hash)
      if metadata.nil?
        return nil
      end
      self.new(hash, metadata)
    end

    # Die Aufgabe bearbeiten.
    def run(cache)
      total = @metadata.word_counts_total
      
      @metadata.word_counts.each_pair do |word, count|
        frequency = count*1.0 / total
        cache[word] << [frequency, count, @hash]
      end
    end
  end
end
