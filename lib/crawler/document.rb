require 'digest/md5'

module Crawler
  # Repräsentiert ein gespeichertes Dokument.
  # Dieses wird von DocumentData referenziert.
  # Ein Dokument kann für mehrere Seiten gespeichert worden sein.
  class Document
    attr_accessor :text
    
    def initialize(text)
      @text = text
    end
    
    def hash
      Digest::MD5.hexdigest(@text)
    end
    
    def save
      # Überprüfen ob vielleicht die Datei doch bereits existiert
      path = "db/docs/#{hash}"
      unless File.exists? path
        # Datei schreiben
        File.open(path, "w") do |f|
          f.write(@text)
        end
      end
    end
    
    def self.load(hash)
      path = "db/docs/#{hash}"
      
      if File.exists? path
        Document.new(File.read(path))
      else
        nil
      end
    end
  end
end