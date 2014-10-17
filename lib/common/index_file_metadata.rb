module Common
  # Enthält Informationen darüber wo man in der IndexFile-Datei welche Daten findet.
  # So kann man sich sparen die ganze Datei lesen zu müssen und direkt dort gelesen werden,
  # wo die relevanten Informationen gespeichert sind.
  #
  # Es handelt sich um ein binäres Datenformat folgender Struktur:
  # Reihen folgender Struktur
  # - FIRST_ROW (16B, Erste Reihe des Datensatzes)
  # - POSITION (4B, Position des ersten Begriffes im Dokument)
  # - LENGTH   (4B, Länge des Abschnittes (der letzte kann kürzer sein, etc.))
  class IndexFileMetadata
    def initialize(path)
      @path = path
    end
    
    def read
      # Index einlesen
      index_raw = File.read(@path)
      @index = []
      count  = index_raw.bytesize / 24 # Jeder Eintrag besteht aus 24B
      (0...count).each do |i|
        first_row_str = raw.byteslice(24*i, 16)
        position_int  = raw.byteslice(24*i+16, 4).unpack("I>")[0]
        length_int    = raw.byteslice(24*i+20, 4).unpack("I>")[0]
        @index << [first_row_str, position_int, length_int]
      end
    end
    
    # Findet die Stellen des Indexfiles in dem das Dokument mit document_id vorkommen könnte.
    def locate_document(document_id)
      # TODO: Dies hier funktioniert nicht, aber wahrscheinlich wird diese Methode
      #       später sowieso in einer anderen Form benötigt...
      
      # Wir generieren die maximale und die minimale Zeile nach der gesucht werden soll
      min_row = [document_id].pack("h*")
      max_row = [(document_id.to_i(16)+1).to_s(16)].pack("h*")
      
      # Resultate finden
      @index.select{|row| row[0] >= min_row && row[0] < max_row}
    end
    
    def generate_for(index_file)
      # TODO
      raise NotImplementedError
    end
  end
end
