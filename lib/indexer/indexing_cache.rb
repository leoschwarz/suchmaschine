module Indexer
  class IndexingCache
    MAX_SIZE = 300_000_000
    
    def initialize(flush_directory)
      @data = {}
      @data_size = 0
      @data_mutex = Mutex.new
      @flush_mutex = Mutex.new
      @flush_directory = flush_directory
      @flush_thread    = Thread.new{}
      @flushes = 0
    end
    
    def add(word, freq, doc)
      @data_mutex.synchronize do
        @data[word] ||= Array.new
        @data[word] << [freq, doc]
        @data_size += Common::IndexFile::IndexFile::ROW_SIZE * 1.5 # <- Ruby-Ineffizienz Heuristik
      end
      
      flush if @data_size >= MAX_SIZE
    end
    
    def flush
      # Sicherstellen, dass die Methode zuerst fertig aufgerufen wird, bevor ein neuer Thread an die Reihe kommt.
      @flush_mutex.synchronize do
        return if @data_size < MAX_SIZE
        
        @flush_thread = nil unless @flush_thread.alive?
        @flush_thread ||= Thread.new do
          file = Common::IndexFile.new(File.join(@flush_directory, @flushes.to_s)).writer
          @data_mutex.synchronize do
            @data.sort_by{|word, rows| word}.each do |word, rows|
              file.write_header(word, rows.size)
              file.write_rows(rows.sort_by{|freq, doc| freq}.reverse)
            end
            @data.clear
            @data_size = 0
          end
          file.flush
          @flushes += 1
        end
        @flush_thread.join
      end
    end
    
    # Im Gegensatz zu einem Aufruf von flush wird hier sicher gestellt dass ALLE Daten gespeichert werden...
    def final_flush
      if @flush_thread && @flush_thread.alive?
        # Warten bis dieser abgeschlossen ist...
        @flush_thread.join
        @flush_thread = nil
      end      
      flush
    end
  end
end
