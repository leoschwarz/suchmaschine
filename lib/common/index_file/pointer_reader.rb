module Common  
  module IndexFile
    class PointerReader
      BUFFER_SIZE = 250_000
    
      def initialize(file_path, file_size)
        @file_path = file_path
        @file_size = file_size
        
        @buffer    = []
        @pointer   = 0  # <- wo muss in der datei weitergelesen werden um den buffer zu ergänzen
      end
    
      def current
        fetch_buffer if @buffer.empty?
        @buffer[0]
      end
    
      def shift
        @buffer.delete_at(0)
        fetch_buffer if @buffer.empty?
        @buffer[0]
      end
    
      private
      # Liest neue Einträge in den Puffer, sofern dies möglich ist.
      def fetch_buffer
        if @pointer < @file_size
          # Rohdaten
          raw = IO.binread(@file_path, BUFFER_SIZE, @pointer)
          
          pointer = 0
          loop do
            # Falls wir bereits das Frequenz/Header-Markier Feld nicht laden können, wird diese Schleife abgebrochen.
            freq_raw = raw.byteslice(pointer, 4)
            break if freq_raw.nil? || freq_raw.bytesize != 4
            
            # Falls freq genau 0.0 ist, handelt es sich um einen Header.
            freq = freq_raw.unpack("g")[0]
            if freq == 0.0
              type = :header
              bytes = IndexFile::HEADER_SIZE
            else
              type = :row
              bytes = IndexFile::ROW_SIZE
            end
          
            # Falls das Ende des Schnipsel ausserhalb des Rohstrings liegt, wird diese Schleife abgebrochen.
            break if pointer + bytes > raw.bytesize
            
            # Die jeweiligen Daten laden
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
end
