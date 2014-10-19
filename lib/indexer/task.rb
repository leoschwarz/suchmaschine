require 'lz4-ruby'

module Indexer
  class Task
    def initialize(document_hash, text)
      @document_hash = document_hash
      @text          = text
    end

    # Eine neue Aufgabe laden.
    def self.load(path)
      document = Indexer::Document.deserialize(LZ4.uncompress(File.read(path)))
      self.new(document.hash, document.text)
    end

    # Die Aufgabe bearbeiten.
    def run
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen.
      all_words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ")

      # Wörter ab einer Länge von 20 Zeichen werden auf die ersten 20 Zeichen reduziert.
      # Alle Duplikate entfernen...
      all_words = all_words.map{|word| word[0...20]}.uniq

      # Wörter in temporäre Dateien schreiben.
      all_words.each do |word|
        index_tmp_file(word).write_entries([@document_hash])
      end
    end
    
    private
    def index_tmp_file(word)
      Common::IndexFile.new(File.join(Config.paths.index_tmp, "word:#{word}"))
    end
  end
end
