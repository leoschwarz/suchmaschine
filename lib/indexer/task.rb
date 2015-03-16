############################################################################################
# Eine Aufgabe des Indexierers beschreibt die Aufgabe ein Dokument zu lesen und die für    #
# Stichworte Einträge im IndexingCache zu hinterlassen. Die Aufgabe beinhaltet nicht das   #
# zusammenführen der einzelnen Zwischenergebnissdateien.                                   #
############################################################################################
module Indexer
  class Task
    def initialize(indexing_cache, metadata_key)
      @indexing_cache = indexing_cache
      @metadata_key   = metadata_key
    end

    def run(db)
      # Metadaten laden.
      raw = db.datastore_get(:metadata, @metadata_key)
      metadata = Common::Database::Metadata.deserialize(raw)
      return if metadata.nil?

      # Zuerst die totale Anzahl an Worten bestimmen.
      total_words = metadata.word_counts.values.inject(:+)

      # Nun die Resultate finden
      key = metadata.hash
      metadata.word_counts.each_pair do |word, count|
        term_frequency = count.to_f / total_words
        @indexing_cache.add(word, term_frequency, key)
      end
    end
  end
end
