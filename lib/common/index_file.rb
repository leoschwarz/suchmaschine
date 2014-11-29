module Common
  # Diese Klasse stellt eine einfache Schnittstelle zu IndexFileWriter und IndexFilePointerReader zur Verfügung,
  # welche das einfache schreiben und lesen von Index-Dateien ermöglichen.
  #
  # Die Index Dateien besitzen ein eigenens spezielles binäres Format:
  # [WORT-28] = 28 Bytes langes Stichwort (Nullybytes werden am Ende hinzugefügt, falls das Stichwort kürzer ist).
  # [FREQ-04] = 4  Bytes lange  Fliesskommazahl welche die Termfrequenz im Dokument angibt.
  # [DOKU-16] = 16 Bytes lange  Hexadezimalzahl/String zur Kennzeichnung des Dokumentes.
  # [ANZA-04] = 4  Bytes lange  Integerzahl welche die Anzahl Dokumente für das entsprechende Stichwort auflistet.
  #
  # Die Elemente liegen immer in einer der beiden Annordnungen vor:
  # - [FREQ-04][WORT-20][ANZA-04] : Dies markiert einen neuen Abschnitt für ein Stichwort,
  #                                 das Feld der Frequenz wird auf 0 gesetzt um diesen Abschnitt zu markieren.
  # - [FREQ-04][DOKU-16]          : Es gibt jeweils für jedes Auftreten pro Dokument eine solche Zeile,
  #                                 das Feld der Frequenz wird immer auf einen Wert ≠ 0 gesetzt um diesen Abschnit zu markieren.
  class IndexFile
    HEADER_PACK = "g a28 L>"
    ROW_PACK    = "g h32"
    HEADER_SIZE = 28
    ROW_SIZE    = 20
    
    def initialize(path)
      @path   = path
      @exists = File.exists?(path)
      if @exists
        @size = File.size(path)
      else
        @size = 0
      end
    end
    
    def pointer_reader
      IndexFilePointerReader.new(@path, @size)
    end
    
    def writer(buffer_max=1024*1024)
      IndexFileWriter.new(@path, @size, buffer_max)
    end
  end
  
  class IndexFileWriter
    def initialize(path, size, buffer_max)
      @path   = path
      @size   = size
      @buffer = ""
      @buffer_max = buffer_max
    end
    
    def write_header(word, n)
      @buffer << [0, word, n].pack(IndexFile::HEADER_PACK)
      flush if @buffer.bytesize > @buffer_max
    end
    
    def write_row(freq, doc)
      @buffer << [freq, doc].pack(IndexFile::ROW_PACK)
      flush if @buffer.bytesize > @buffer_max
    end
    
    def flush
      # @size <=> offset
      IO.binwrite(@path, @buffer, @size)
      @size += @buffer.bytesize
      @buffer.clear
    end
  end
  
  class IndexFilePointerReader
    BUFFER_SIZE = 250_000
    
    def initialize(file_path, file_size)
      @file_path = file_path
      @file_size = file_size
      @file_offset = 0
      @buffer  = ""
      @buffer_offset = 0
      @buffer_last = false # wahr wenn das letzte Byte des Buffers das letzte Byte der Datei ist.
      @current = nil
      @end = false
    end
    
    # Array: [TYPE={:header oder :row}, Komponenten...]
    def current
      return nil if @end
      
      if @current.nil?
        frequency = @buffer.byteslice(@buffer_offset, 4)
        if frequency != 0
          # Es handelt sich um einen normalen Eintrag
          data = @buffer.byteslice(@buffer_offset, IndexFile::ROW_SIZE).unpack(IndexFile::ROW_PACK)
          @current = [:row, data[0], data[1]]
        else
          # Es handelt sich um einen Header.
          data = @buffer.byteslice(@buffer_offset, IndexFile::HEADER_SIZE).unpack(IndexFile::HEADER_PACK)
          @current = [:header, data[1], data[2]]
        end
      end
      @current
    end
    
    def shift
      skip_bytes = case current[0]
        when :header then IndexFile::HEADER_SIZE
        when :row    then IndexFile::ROW_SIZE
      end
      
      @buffer_offset += BUFFER_SIZE      
      if @buffer_last && @buffer_offset >= @buffer_offset >= @buffer.bytesize
        # Das Ende der Datei wurde erreicht.
        @end = true
      elsif !@buffer_last && @buffer.bytesize - @buffer_offset < 100 # Indem im Voraus geladen wird, wird vermieden komplizierte Logik für das Nachladen von weiteren Einträgen zu implementieren, was nötig wäre, wenn der Buffer einen Eintrag zertrennen würde...
        
        @file_offset += @buffer_offset
        @buffer = @buffer.byteslice(@buffer_offset, BUFFER_SIZE) || ""
        @buffer_offset = 0
        @buffer << IO.binread(@file_path, @file_offset, BUFFER_SIZE)
        @buffer_last = (@file_offset+BUFFER_SIZE >= @file_size)
      end
      @current = nil
    end
  end
end
