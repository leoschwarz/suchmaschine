# TODO: Diese Datei noch sinnvoll umbenennen...

module Indexer
  class Task
    def initialize(indexing_cache, metadata)
      @indexing_cache = indexing_cache
      @metadata       = metadata
    end
    
    def run
      # Zuerst die totale Anzahl an Worten bestimmen.
      total_words = @metadata.word_counts.values.inject(:+)
      
      # Nun die Resultate finden
      key = @metadata.hash
      @metadata.word_counts.each_pair do |word, count|
        term_frequency = count.to_f / total_words
        @indexing_cache.add(word, term_frequency, key)
      end
    end
  end
end
