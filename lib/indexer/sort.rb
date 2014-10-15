# Implementiert einen External Mergesort um die temporären Indexdateien abschliessend zu sortieren.
# Literatur: http://dblab.cs.toronto.edu/courses/443/2014/07.sorting.html
# Ausführlichere Erläuterung: https://www.youtube.com/watch?v=Kg4bqzAqRBM

module Indexer
  class StringBuffer
    def initialize(string, size)
      @string = string
      @pointer = 0
      @size = size
    end
    
    # Liest die nächsten Bytes.
    def next
      result = @string[@pointer...@pointer+@size]
      @pointer += @size
      result
    end
    
    # Liest die zuletzt gelesenen Bytes erneut
    def read
      @string[@pointer...@pointer+@size]
    end
  end
  
  class IndexSorter
    # Die maximale Anzahl Reihen eines Dokumentes die geladen werden soll.
    # Jede Reihe ist 20B gross, sodass sich für 500'000 Reihen 10MB ergeben.
    MAX_ROWS = 500_000
    ROW_SIZE = Common::IndexFile::ROW_SIZE
    
    # Beide Parameter sollen Common::IndexFile Objekte sein.
    def self.sort(unsorted_file, destination_file)
      chunks = (unsorted_file.rows *1.0 / MAX_ROWS).ceil
      
      # Da es wahrscheinlich öfters vorkommt, dass weniger Einträge als die Maximalzahl
      # vorhanden sind, gibt es hier eine spezielle, einfachere, Prozedur für diese:
      if chunks == 1
        # In-Memory Sortierung des gesamten Dokumentes.
        sorted_entries = dumb_sort( unsorted_file.read_bin_entries )
        destination_file.write_bin_entries(sorted_entries)
      else
        # External Mergesort
        self.merge_sort(unsorted_file, destination_file, chunks)
      end
    end
    
    def self.dumb_sort(entries)
      entries.sort # <-- TODO hier eventuell selbstimplementierten Algorithmus verwenden.
    end
    
    # TODO: Diese Methode ist zZ. noch mehr ein Platzhalter
    # TODO: Richtiges Merge Sort muss noch implementiert werden.
    def self.merge_sort(source_file, destination_file, chunks)
      # In einem allerersten Schritt werden die einzelnen Chunks mit Dumbsort sortiert.
      temp_file = Common::IndexFile.new("/tmp/lala") # TODO !!!!!! 
      (0...chunks).each do |chunk_i|
        sorted_entries = dumb_sort( unsorted_file.read_bin_entries(chunk_i*ROW_SIZE*MAX_ROWS, MAX_ROWS) )
        temp_file.write_bin_entries(sorted_entries)
      end
      
      # TODO : Rekursion wenn zuviele chunks!!
      # TODO : Output bufern und nach dem erreichen eines Schwellenwertes schreiben, damit das nicht alles im RAM bleibt.
      open_chunks = (0...chunks).map{|chunk_i| StringBuffer.new(temp_file.read_bin_raw(chunk_i*ROW_SIZE*MAX_ROWS, MAX_ROWS), ROW_SIZE) }
      result      = ""
      while open_chunks.size > 0
        # Minimum finden.
        min_index = 0
        min_value = open_chunks[0].read      
        open_chunks[1..-1].each_with_index do |open_chunk, index|
          value = open_chunk.read
          if value < min_value
            min_value = value
            min_index = index
          end
        end
        
        # Minimum zum Resultat hinzufügen.
        result += min_value
        
        # Den pointer des chunk verschieben und auf nil überprüfen
        if open_chunks[min_index].next.nil?
          open_chunks.delete_at(min_index)
        end
      end
      
      destination_file.write_bin_raw(result)
      
      # TODO: Tempfile löschen
    end
  end
end
