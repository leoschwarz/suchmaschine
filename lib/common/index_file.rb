module Common
  # Der Index verwendet ein eigenes binäres Datenformat,
  # die einzelnen Werte folgen direkt aufeinander, deshalb ist die Einhaltung der Längen der einzelnen Werte essenziel.
  #
  # Die Einträge müssen nach DOCUMENT_ID sortiert sein, ausserdem darf ein Dokument jeweils nur in einem
  # DATA_INDEX Abschnit vorkommen (damit nacher einfacher danach gesucht werden kann.. Siehe find_*)
  #
  # Positionen bezeichnen die Anzahl Bytes die übersprungen werden muss.
  #
  # DATA_OFFSET(4B, Start der Auflistung der einzelnen Vorkommen des Begriffes)
  # DATA_INDEX: (Interner Index über die Datei. Ermöglicht das schnelle Finden von Einträgen in grossen Dateien.)
  #             (Reihen folgender Struktur:)
  # - FIRST_DOCUMENT_ID (16B)
  # - POSITION    (4B, Position des ersten Begriffes im Dokument)
  # - LENGTH      (4B, Länge des Abschnittes (der letzte kann kürzer sein, etc.))
  # DATA: (Reihen folgender Struktur:)
  # - DOCUMENT_ID: (16B)
  # - POSITION: (4B, Position in der Liste der Wörter des Dokumentes.)
  class IndexFile
    # Anzahl Einträge in einem normalen Abschnitt
    # Dieser Wert kann überschritten werden, wenn mehrere Einträge des selben Dokumentes ansonsten auf verschiedene
    # Abschnitte fallen würden.
    DEFAULT_SECTION_LENGTH = 5000 # 100KB
    
    def initialize(path)
      @path = path
    end
    
    # Liest die Metdaten des Dokumentes ein,
    # das sind: DATA_OFFSET und DATA_INDEX aber nicht: DATA
    def read_metadata
      @data_offset = IO.binread(@path, 4).unpack("I")[0]
      index_length = @data_offset - 4
      index_raw    = IO.binread(@path, index_length, 4)
      
      # Index einlesen
      @index = []
      count  = index_raw.bytesize / 24 # Jeder Eintrag besteht aus 24B
      (0...count).each do |i|
        first_document_id_str = raw.byteslice(24*i, 16)
        # Das konvertieren zu einem Binärstring und das erst anschliessende Umwandeln in eine Integer ist
        # deshalb notwendig, da die Zahl 16Bytes lang ist und unter umständen die Bigint Klasse verwenden
        # kann, für die es keinen pack/unpack Befehl gibt.
        first_document_id_int = document_id_str.unpack("B*")[0].to_i(2)
        position_int          = raw.byteslice(24*i+16, 4).unpack("I")[0]
        length_int            = raw.byteslice(24*i+20, 4).unpack("I")[0]
        @index << [first_document_id_int, position_int, length_int]
      end
    end
    
    # Liest Einträge aus der Datei.
    # data_offset: Position ab der gelesen werden soll
    # data_length: Bytes die gelesen werden sollen (muss durch 20 dividierbar sein)
    def read_data(data_offset, data_length)
      # Binärdaten lesen
      raw = IO.binread(@path, data_length, data_offset)
      
      # Verarbeiten, dh. immer 20B lange Stücke nehmen
      entries = []
      count   = raw.bytesize / 20
      (0...count).each do |i|
        document_id_str = raw.byteslice(20*i, 16)
        document_id_int = document_id_str.unpack("B*")[0].to_i(2)
        position_int    = raw.byteslice(20*i+16, 4).unpack("I")[0]
        entries << [document_id_int, position_int]
      end
      
      # Die Einträge zurückgeben
      entries
    end
    
    # Gibt ein Array mit den Indexen der Wörter im Dokument zurück (kann auch leer sein)
    def find_document_occurences(document_id)
      candidate_index_section = @index.reverse.bsearch{|item| item[0] <= document_id}
      return [] if candidate_index_section.nil? # Das kommt vor wenn der erste Index-Abschnitt mit einer höheren ID als die hiesiege beginnt.
      
      data = read_data(candidate_index_section[1], candidate_index_section[2])
      data.select{|item| item[0] == document_id}.map{|item| item[1]}
    end
  end
end
