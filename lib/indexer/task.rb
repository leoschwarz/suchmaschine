module Indexer
  class Task
    def initialize(document_hash, text)
      @document_hash = document_hash
      @text          = text
    end

    # Eine neue Aufgabe laden.
    def self.fetch
      docinfo_hash = Indexer::Database.index_queue_fetch
      docinfo      = Indexer::DocumentInfo.load(docinfo_hash)
      doc          = Indexer::Document.load(docinfo.document_hash)
      text         = doc.text
      self.new(doc.hash, text)
    end

    # Die Aufgabe bearbeiten.
    def run
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen.
      all_words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ")

      # Wörter ab einer Länge von 20 Zeichen werden auf die ersten 20 Zeichen reduziert.
      # Duplikate werden entfernt.
      all_words = all_words.map{|word| word[0...20]}.uniq

      # Wörter in Datenbank registrieren.
      all_words.each_slice(100) do |words|
        Indexer::Database.index_append(words.map{|word| [word, @document_hash]})
      end
    end
  end
end
