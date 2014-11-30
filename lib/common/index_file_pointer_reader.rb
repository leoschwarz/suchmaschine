module Common  
  class IndexFilePointerReader
    BUFFER_SIZE = 250_000
    
    def initialize(file_path, file_size)
      @file_path = File.expand_path file_path
      @file_size = file_size
      
      @buffer    = []
      @pointer   = 0  # <- wo muss in der datei weitergelesen werden um den buffer zu ergänzen
    end
    
    def current
      if @buffer.empty?
        fetch_buffer
        @buffer[0] = nil if @buffer.empty?
      end
      @buffer[0]
    end
    
    def shift
      @buffer.delete_at(0)
      fetch_buffer if @buffer.empty?
      @buffer[0]
    end
    
    private
    def fetch_buffer
      if @pointer < @file_size
        raw = IO.binread(@file_path, BUFFER_SIZE, @pointer)
        
        # Einlesen
        pointer = 0
        loop do
          freq_raw = raw.byteslice(pointer, 4)
          if freq_raw.nil? || freq_raw.bytesize != 4
            break
          end
          
          freq = freq_raw.unpack("g")[0]
          if freq == 0.0
            type = :header
            bytes = IndexFile::HEADER_SIZE
          else
            type = :row
            bytes = IndexFile::ROW_SIZE
          end
          
          if pointer + bytes > raw.bytesize
            break
          end
          
          if type == :header
            _, word, n = raw.byteslice(pointer, bytes).unpack(IndexFile::HEADER_PACK)
            @buffer << [:header, word, n]
          elsif type == :row
            freq, doc = raw.byteslice(pointer, bytes).unpack(IndexFile::ROW_PACK)
            @buffer << [:row, freq, doc]
          end
          pointer += bytes
        end
        
        @pointer += pointer
      end
    end
  end
end