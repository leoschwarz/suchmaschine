# TODO: Diese Datei noch sinnvol umbenennen...

module Indexer
  class Task
    def initialize(hash, metadata)
      @hash     = hash
      @metadata = metadata
    end

    # Eine neue Aufgabe laden.
    def self.load(hash)
      metadata = Indexer::Metadata.load(hash)
      if metadata.nil?
        return nil
      end
      self.new(hash, metadata)
    end

    # Die Aufgabe bearbeiten.
    def run(cache)
      @metadata.word_counts.each_pair do |word, count|
        # TODO: Dies ist natürlich falsch, aber nun nur zu Testzwecken...
        frequency = Math.log(count)
        cache[word] << [frequency, count, @hash]
      end
    end
  end
end
