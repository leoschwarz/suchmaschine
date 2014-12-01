module Common  
  module IndexFile
    class PointerReader
      def initialize(file_path, file_size)
        @file_path = file_path
        @file_size = file_size
        
        # Der erste Header wird bereits jetzt gelesen
        header   = IO.binread(@file_path, IndexFile::HEADER_SIZE, 0).unpack(IndexFile::HEADER_PACK)
        @buffer  = [[:header, header[1], header[2]]]
        @next_position = IndexFile::HEADER_SIZE
        @next_rowcount = header[2]
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
      # Liest den nächsten Abschnitt an Zeilen, und dann den nächsten Header ein. (falls einer existiert...)
      def fetch_buffer
        size_without_header        = IndexFile::ROW_SIZE*@next_rowcount
        size_with_following_header = IndexFile::ROW_SIZE*@next_rowcount + IndexFile::HEADER_SIZE
        if @next_position + size_with_following_header <= @file_size
          # Wir können alles lesen, dh. am Ende gibt es einen Header um weiterzulesen...
          raw = IO.binread(@file_path, size_with_following_header, @next_position)
          rows = raw.byteslice(0, size_without_header).unpack(IndexFile::ROW_PACK*@next_rowcount)
          rows.each_slice(2) do |freq, doc|
            @buffer << [:row, freq, doc]
          end
          header = raw.byteslice(size_without_header, IndexFile::HEADER_SIZE).unpack(IndexFile::HEADER_PACK)
          @buffer << [:header, header[1], header[2]]
          
          @next_position += size_with_following_header
          @next_rowcount  = header[2]
        else
          # Wir können nur die Zeilen lesen, dh. am Ende gibt es keinen Header zum weiterlesen...
          raw = IO.binread(@file_path, size_without_header, @next_position)
          
          rows = raw.unpack(IndexFile::ROW_PACK*@next_rowcount)
          rows.each_slice(2) do |freq, doc|
            @buffer << [:row, freq, doc]
          end
          
          @next_position += size_without_header + 1
          @next_rowcount = 0
        end
      end
    end
  end
end
