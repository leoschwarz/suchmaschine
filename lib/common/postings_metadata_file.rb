module Common
  # Enthält Informationen darüber wo man in der IndexFile-Datei welche Daten findet.
  # So kann man sich sparen die ganze Datei lesen zu müssen und direkt dort gelesen werden,
  # wo die relevanten Informationen gespeichert sind.
  #
  # Es handelt sich um ein binäres Datenformat folgender Struktur:
  # - TOTAL_OCCURENCES (8B uint64)
  # danach: Reihen folgender Struktur:
  # - FIRST_ROW (20B, Erste Reihe des Datensatzes)
  # - POSITION (4B, Position des ersten Begriffes im Dokument)
  # - LENGTH   (4B, Länge des Abschnittes (der letzte kann kürzer sein, etc.))
  class PostingsMetadataFile
    def initialize(path)
      @path = path
    end
    
    attr_reader :total_occurences
    
    def read
      # Index einlesen
      index_raw = File.read(@path)
      @total_occurences = raw.byteslice(0, 8).unpack("L_>")[0]
      
      count  = (index_raw.bytesize-8) / 28 # Jeder Eintrag besteht aus 28B
      @index = (0...count).map do |i|
        raw.byteslice()
        first_row_str = raw.byteslice(8+28*i, 20)
        position_int  = raw.byteslice(8+28*i+20, 4).unpack("I>")[0]
        length_int    = raw.byteslice(8+28*i+24, 4).unpack("I>")[0]
        @index << [first_row_str, position_int, length_int]
      end
    end
    
#    # Findet die Stellen des Indexfiles in dem das Dokument mit document_id vorkommen könnte.
#    def locate_document(document_id)
#      # TODO: Dies hier funktioniert nicht, aber wahrscheinlich wird diese Methode
#      #       später sowieso in einer anderen Form benötigt...
#      
#      # Wir generieren die maximale und die minimale Zeile nach der gesucht werden soll
#      min_row = [document_id].pack("h*")
#      max_row = [(document_id.to_i(16)+1).to_s(16)].pack("h*")
#      
#      # Resultate finden
#      @index.select{|row| row[0] >= min_row && row[0] < max_row}
#    end
    
    def generate_for(postings_file)
      file = File.open(@path, "w")
      
      total_occurences = postings_file.read_entries.map{|row| row[1]}.inject(:+)
      file.write( [total_occurences].pack("L_>") )
      # TODO: PostingFile.chunks etc. hinzufügen, danach diese hier indexieren...
      file.close
    end
  end
end
