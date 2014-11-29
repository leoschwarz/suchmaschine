module Indexer
  class IndexingCache
    MAX_SIZE = 300_000_000
    
    def initialize(flush_directory)
      @data = {}
      @data_size = 0
      @flush_directory = flush_directory
      @flush_thread    = nil
      @flushes = 0
    end
    
    def add(word, freq, doc)
      @data[word] ||= Array.new
      @data[word] << [freq, doc]
      @data_size += Common::IndexFile::ROW_SIZE * 1.5 # <- Ruby-Ineffizienz Heuristik
      
      flush if @data_size >= MAX_SIZE
    end
    
    def flush
      if @flush_thread.nil? || !@flush_thread.alive?
        @flush_thread = Thread.new do
          file = Common::IndexFile.new(File.join(@flush_directory, @flushes.to_s)).writer
      
          @data.sort_by{|word, rows| word}.each do |word, rows|
            file.write_header(word, rows.size)
            rows.sort_by{|freq, doc| freq}.reverse.each do |freq, doc|
              file.write_row(freq, doc)
            end
          end
      
          file.flush
      
          @flushes += 1
          @data.clear
          @data_size = 0
        end
      else
        @flush_thread.join
      end
    end
  end
end
