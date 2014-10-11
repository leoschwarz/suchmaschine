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
      
      if doc.nil?
        # Dies kommt vor wenn nur DOCUMENT_INFO aber kein DOCUMENT gespeichert wurde.
        self.fetch
      else
        self.new(doc.hash, doc.text)
      end
    end

    # Die Aufgabe bearbeiten.
    def run
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen.
      all_words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ")

      # Wörter ab einer Länge von 20 Zeichen werden auf die ersten 20 Zeichen reduziert.
      all_words = all_words.map{|word| word[0...20]}

      # Wörter in Datenbank registrieren.
      # Jeder Eintrag wird auch noch mit dem Index im Text gespeichert.
      all_words.each_with_index.each_slice(100) do |words|
        Indexer::Database.index_append(words.map{|word, index| [word, "#{index}:#{@document_hash}"]})
      end
    end
  end
end
