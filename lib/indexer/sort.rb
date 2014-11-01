# Implementiert einen External Mergesort um die temporären Indexdateien abschliessend zu sortieren.
# Literatur: http://dblab.cs.toronto.edu/courses/443/2014/07.sorting.html
# Ausführlichere Erläuterung: https://www.youtube.com/watch?v=Kg4bqzAqRBM

require 'securerandom'

# TODO: Da hier wahrscheinlich noch Fehler lauern, würde ein ausführlicher Test
#       der Prozeduren 
# TODO: Noch einmals überarbeiten und aufräumen.

module Indexer
  class PostingsFileChunk
    # Die maximale Anzahl Reihen eines Dokumentes die geladen werden soll.
    # Dies gilt für *ein* Stück/Chunk.
    # Jede Reihe ist 20B gross, sodass sich für 500'000 Reihen 10MB ergeben.
    MAX_ROWS = 500_000
    
    attr_reader :rows
    
    def initialize(postings_file, chunk_index)
      @postings_file  = postings_file
      @chunk_index = chunk_index
      @row_pointer = 0
    end
    
    # Erst wenn diese Methode aufgerufen wird, werden die Daten aus der Datei in den Arbeitspeicher gelesen.
    def load
      @rows = @postings_file.read_bin_entries(@chunk_index*MAX_ROWS, MAX_ROWS)
    end
    
    def shift_pointer
      @row_pointer += 1
    end
    
    def current_row
      @rows[@row_pointer]
    end
  end
  
  class PostingsFileBufferedWriter
    MAX_ROWS = 500_000
    
    def initialize(file)
      @file = file
      @rows = []
    end
    
    def << (row)
      @rows << row
    end
    
    def save
      @file.write_bin_entries(@rows)
    end
  end
  
  class PostingsFileChunkList
    def initialize(chunks)
      @chunks = chunks
      @chunks[0].load unless @chunks[0].nil?
    end
    
    def current
      if @chunks.size == 0
        return nil
      end
      
      if @chunks[0].current_row.nil?
        @chunks.delete_at(0)
        @chunks[0].load unless @chunks[0].nil?
      end
      
      @chunks[0]
    end
  end

  
  class IndexSorter
    # Die maximale Anzahl Reihen eines Dokumentes die geladen werden soll.
    # Dies gilt für *ein* Stück/Chunk.
    # Jede Reihe ist 20B gross, sodass sich für 500'000 Reihen 10MB ergeben.
    MAX_ROWS = 500_000
    ROW_SIZE = Common::PostingsFile::ROW_SIZE
    # Die maximale Anzahl Stücke der grösse MAX_ROWS die geladen werden darf. 
    MAX_CHUNKS = 6
    
    # Beide Parameter sollen Common::PostingsFile Objekte sein.
    def self.sort(unsorted_file, destination_file)
      chunks = (unsorted_file.rows_count() *1.0 / MAX_ROWS).ceil
      
      # Da es wahrscheinlich öfters vorkommt, dass weniger Einträge als die Maximalzahl
      # vorhanden sind, gibt es hier eine spezielle, einfachere, Prozedur für diese:
      if chunks == 1
        # In-Memory Sortierung des gesamten Dokumentes.
        sorted_entries = dumb_sort( unsorted_file.read_bin_entries )
        destination_file.write_bin_entries(sorted_entries)
      else
        # In einem allerersten Schritt werden die einzelnen Chunks mit Dumbsort sortiert.
        temp_file = Common::PostingsFile.new(self.new_temp_file_path)
        (0...chunks).each do |chunk_i| # TODO Später evtl einen speziellen Enumerator verwenden.
          chunk = PostingsFileChunk.new(temp_file, chunk_i)
          chunk.load
          temp_file.write_bin_entries( dumb_sort(chunk.rows) )
        end
        
        # External Mergesort
        self.merge_sort(temp_file, destination_file, chunks)
        
        # Tempfile löschen
        File.unlink temp_file.path
      end
    end
    
    def self.dumb_sort(entries)
      entries.sort # <-- TODO hier eventuell selbstimplementierten Algorithmus verwenden.
    end
        
    # Sortiert die vorsortierten Stücke in source_file.
    # source_file: Common::PostingsFile
    # output_file: Common::PostingsFile
    # chunks_n: Integer, Anzahl Stücke in der Datei. Jeweils MAX_ROWS*ROW_SIZE gross, das letzte ist unter Umständen aber kleiner.
    # chunk_range: Range, nil: Falls Range ein spezieller Indexbereich für den PostingsFileChunks berücksichtigt werden sollen.
    #                          Falls nil, dann wird die ganze Datei berücksichtigt.
    # TODO: Hier könnten noch ein paar böse Fehler lauern.
    def self.merge_sort(source_file, destination_file, chunks_n, chunk_range=nil)
      # Falls die Anzahl Stücke nun zu gross ist, müssen diese aufgeteilt werden
      if chunks_n > MAX_CHUNKS
        # Die maximal im RAM zu bearbeitende Anzahl Chunks liegt bei MAX_CHUNKS.
        # Deshalb werden [MAX_CHUNKS] viele PostingsFileChunkList Objekte erzeugt.
        # Zuerst werden aber neue, leere Temporäre Dateien erzeugt, die durch Rekursion befüllt werden.
        # Index/Range-Berechnungen:
        sorted_subfiles_chunks_n = (0...MAX_CHUNKS).map do |index|
          n    = (chunks_n / MAX_CHUNKS).floor
          rest = chunks_n % MAX_CHUNKS
          n   += rest if rest < index
          n
        end
        sorted_subfiles_chunks_starts = (0...MAX_CHUNKS).each do |i|
          sorted_subfiles_chunks_n[0...i].inject(:+)
        end
        
        # Rekursion
        sorted_subfiles = (0...MAX_CHUNKS).map{ Common::PostingsFile.new(self.new_temp_file_path, true) }
        sorted_subfiles.each_with_index do |subfile, index|
          range = sorted_subfiles_chunks_starts[index]...(sorted_subfiles_chunks_starts[index]+sorted_subfiles_chunks_n[index])
          self.merge_sort(source_file, subfile, sorted_subfiles_chunks_n[index], range)
        end
        
        # Nun sind die jeweilgen Dateien der sorted_subfiles sortiert. Wir müssen lediglich noch diese zusammenlegen.
        # Da jedoch die einzelnen sorted_subfiles auch mehrere Chunks enthalten könnten, werden zur Sicherheit
        # die Chunks in eine PostingsFileChunkList geladen, die sicherstellt dass immer nur ein Chunk geladen ist.
        chunk_lists = []
        sorted_subfiles.each_with_index do |subfile, index|
          chunks = (0...sorted_subfiles_chunks_n[index]).map{|i| PostingsFileChunk.new(subfile, i)}
          chunk_lists << PostingsFileChunkList.new(chunks)
        end
        
        result = PostingsFileBufferedWriter.new(destination_file)
        while chunk_lists.size > 0
          # Minimum finden
          min_index = 0
          min_value = chunk_lists[0].current.current_row
          chunk_lists[1..-1].each_with_index do |chunk_list, index|
            if chunk_list.current.current_row < min_value
              min_value = chunk_list.current.current_row
              min_index = index
            end
          end
          
          # Minimum zum Resultat hinzufügen.
          result << min_value
          
          # Den Pointer des Chunks verschieben und auf Ende überprüfen
          chunk_lists[min_index].current.shift_pointer
          if chunk_lists[min_index].current.nil?
            chunk_lists.delete_at(min_index)
          end
        end
        
        # Eventuell noch nicht geschriebene Buffer-Einträge speichern.
        result.save
        
        # Die Subfiles können nun gelöscht werden, da sie nicht mehr gebraucht werden.
        sorted_subfiles.each do |subfile|
          File.unlink subfile.path
        end
      else
        # Die einzelnen Stücke laden und sortieren.
        chunk_range = 0...chunks_n if chunk_range.nil?
        chunks = chunk_range.map{|i| PostingsFileChunk.new(source_file, i)}
        chunks.each{|chunk| chunk.load}
        result = PostingsFileBufferedWriter.new(destination_file)
        
        # Solange es noch nicht fertig gelesene Stücke hat, werden neue geladen.
        while chunks.size > 0
          # Minimum finden.
          min_index = 0
          min_value = chunks[0].current_row
          chunks[1..-1].each_with_index do |chunk, index|
            if chunk.current_row < min_value
              min_value = chunk.current_row
              min_index = index
            end
          end
          
          # Minimum zum Resultat hinzufügen.
          result << min_value
          
          # Den Pointer des Chunks verschieben und auf Ende überprüfen
          chunks[min_index].shift_pointer
          if chunks[min_index].current_row.nil?
            chunks.delete_at(min_index)
          end
        end
        
        # Eventuell noch nicht geschriebene Buffer-Einträge speichern.
        result.save
      end
    end
    
    def self.new_temp_file_path
      File.join(Config.paths.index_tmp, SecureRandom.uuid)
    end    
  end
end
