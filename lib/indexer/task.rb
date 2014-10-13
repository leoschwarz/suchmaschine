require 'lz4-ruby'

module Indexer
  class Task
    def initialize(document_hash, text)
      @document_hash = document_hash
      @text          = text
    end

    # Eine neue Aufgabe laden.
    def self.load(path)
#      metadata_id = Indexer::Database.index_queue_fetch
#      metadata    = Indexer::Metadata.load(metadata_id)
#      document    = metadata.document
      document = Indexer::Document.deserialize(LZ4.uncompress(File.read(path)))
      document.hash = path.split(":")[-1]
      
      #if document.nil?
      #  # Dies kommt vor wenn nur DOCUMENT_INFO aber kein DOCUMENT gespeichert wurde.
      #  self.fetch
      #else
      self.new(document.hash, document.text)
      #end
    end

    # Die Aufgabe bearbeiten.
    def run
      # Ein Array aller vorkommenden kleingeschriebenen Wörter erzeugen.
      all_words = @text.gsub(/[^a-zA-ZäöüÄÖÜ]+/, " ").downcase.split(" ")

      # Wörter ab einer Länge von 20 Zeichen werden auf die ersten 20 Zeichen reduziert.
      all_words = all_words.map{|word| word[0...20]}

      # Wörter in temporäre Dateien schreiben.
      # Jeder Eintrag wird auch noch mit dem Index im Text gespeichert.
      all_words.each_with_index.group_by{|hit| hit[0]}.each do |_words|
        File.open("/mnt/sdb/suchmaschine/indextmp/word:#{_words[0]}", "a") do |file|
          _words[1].each do |word, line|
            file.puts "#{@document_hash}:#{line}"
          end
        end
      end
    end
  end
end
