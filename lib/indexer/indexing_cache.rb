############################################################################################
# Der Indexierungs-Cache stellt ein einfaches Interface zur Verfügung Auftritsstellen von  #
# Stichworten festzuhalten und diese automatisch nach der Überschreitung eines bestimmten  #
# Schwellenwertes in eine temporärere Index-Datei in einem Verzeichnis zu speichern.       #
############################################################################################
module Indexer
  class IndexingCache
    MAX_SIZE = 250_000_000
    
    def initialize(flush_directory)
      @data = {}
      @data_size = 0
      @data_mutex = Mutex.new
      @flush_mutex = Mutex.new
      @flush_directory = flush_directory
      @flush_thread = Thread.new{}
      @flushes = 0
    end
    
    def add(word, freq, doc)
      @data_mutex.synchronize do
        @data[word] ||= Array.new
        @data[word] << [freq, doc]
        @data_size += Common::IndexFile::IndexFile::ROW_SIZE
      end
      
      flush if @data_size >= MAX_SIZE
    end
    
    def flush(force=false)
      # Sicherstellen, dass die Methode zuerst fertig aufgerufen wurde,
      # bevor ein neuer Thread an die Reihe kommt.
      @flush_mutex.synchronize do
        return if (@data_size < MAX_SIZE) && !force
        
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
    
    # Diese Methode stellt sicher, dass auch die letzten Daten gespeichert wurden.
    # Flush im gegenzug, speichert nur wenn es viele Daten zu speichern gibt.
    def final_flush
      if @flush_thread && @flush_thread.alive?
        # Warten bis dieser abgeschlossen ist...
        @flush_thread.join
        @flush_thread = nil
      end      
      flush(true)
    end
  end
end
