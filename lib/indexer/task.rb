# TODO: Diese Datei noch sinnvol umbenennen...

module Indexer
  class Task
    def initialize(indexing_cache, metadata)
      @indexing_cache = indexing_cache
      @metadata       = metadata
    end
    
    def run
      # Zuerst die Maximal Anzahl eines beliebigen wortes finden...
      max_occurences = 0
      @metadata.word_counts.values.each do |count|
        max_occurences = count if max_occurences < count
      end
      
      # Nun die Resultate finden
      key = @metadata.hash
      @metadata.word_counts.each_pair do |word, count|
        term_frequency = count.to_f / max_occurences
        @indexing_cache.add(word, term_frequency, key)
      end
    end
  end
end
