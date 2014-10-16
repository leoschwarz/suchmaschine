module Common
  # Der Index verwendet ein eigenes binäres Datenformat,
  # es gibt kein Trennzeichen, deshalb ist die Einhaltung der Längen der einzelnen Werte essenziel.
  #
  # Um nacher einfach Vergleichen zu können werden die Zahlen jeweils in Bigendian Reihenfolge gespeichert.
  # Dies entspricht den pack/unpack Parametern: I>, h*, usw.
  #
  # Die Einträge müssen nach DOCUMENT_ID sortiert sein.
  # Informationen zu einer IndexFile-Datei findet man in einer IndexFileMetadata-Datei.
  #
  # Reihen folgender Struktur:
  # - DOCUMENT_ID: (16B)
  # - POSITION: (4B, Position in der Liste der Wörter des Dokumentes.)
  class IndexFile
    ROW_SIZE = 20
    
    attr_reader :path
    
    def initialize(path)
      @path = path
    end
    
    def rows_count
      File.size(@path)/ROW_SIZE
    end
    
    # Liest Einträge aus der Datei, Reihen als Array mit umgewandelten Typen.
    # data_offset: Position ab der gelesen werden soll
    # data_length: Bytes die gelesen werden sollen (muss durch 20 dividierbar sein)
    def read_entries(data_offset=0, data_length=nil)
      read_bin_entries(data_offset, data_length).map do |raw|
        # Gespeichert wird ein Binärstring der aus dem Hexstring entnommen wurde.
        # Deshalb kann dieser mithilfe 'h*' auch wieder als ursprünglicher gelesen werden.
        document_id_str = raw.byteslice(0, 16).unpack("h*")[0]
        position_int    = raw.byteslice(16, 4).unpack("I>")[0]
        [document_id_str, position_int]
      end
    end
    
    # Liest Einträge aus der Datei, Reihen als Binär-String.
    def read_bin_entries(offset=0, length=nil)
      # Binärdaten lesen
      raw = IO.binread(@path, length, offset)
      
      # Immer 20B lange Stücke nehmen
      count = raw.bytesize / 20
      (0...count).map{|i| raw.byteslice(20*i, 20)}
    end
    
    # Liest einen Teil der Datei als Binären String
    def read_bin_raw(offset=0, length=nil)
      IO.binread(@path, length, offset)
    end
    
    # Schreibt Einträge in die Datei, Reihen als Array mit umgewandelten Typen.
    def write_entries(entries)
      write_bin_entries entries.map{|row| row.pack("h*I>")}
    end
    
    # Schreibt Einträge in die Datei, Reihen als Binär-String.
    def write_bin_entries(entries)
      File.open(@path, "ab") do |file|
        file.write(entries.join(""))
      end
    end
  end
end
