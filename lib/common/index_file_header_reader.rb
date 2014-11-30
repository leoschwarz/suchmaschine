module Common
  # Ein Leser für Index-Dateien, der ausschliesslich Header-Zeilen liest.
  # Die restlichen Zeilen werden nicht gelesen, sondern direkt übersprungen, um die Performance zu verbessern.
  # Es wird kein Buffer verwendet, weshalb dies ausschliesslich auf Laufwerken mit sehr kurzer Zugriffszeit verwendet werden sollte (SSD, RAM-Disk, etc)
  # Die einzelnen Zeilen werden als callback zurückgegeben.
  class IndexFileHeaderReader
    def initialize(file_path, file_size)
      @file_path = file_path
      @file_size = file_size
    end
    
    def read
      pointer = 0
      while pointer < @file_size
        _, term, count = IO.binread(@file_path, IndexFile::HEADER_SIZE, pointer)
        offset = pointer + IndexFile::HEADER_SIZE
        yield(term, count, offset) # <-- callback
        pointer += count * IndexFile::ROW_SIZE
      end
    end
  end
end
