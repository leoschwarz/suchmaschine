module Common
  module IndexFile
    class Writer
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
    
      def write_rows(pairs)
        @buffer << pairs.flatten.pack(IndexFile::ROW_PACK * pairs.size)
        flush if @buffer.bytesize > @buffer_max
      end
    
      def flush
        # @size <=> offset
        IO.binwrite(@path, @buffer, @size)
        @size += @buffer.bytesize
        @buffer.clear
      end
    end
  end
end
