module Common
  module IndexFile
    class Metadata
      ROW_SIZE = 32
      ROW_PACK = "a20 L> Q> "
      
      attr_reader :documents_count
      
      def initialize(index_file)
        @index_file = index_file
        @path       = index_file.path + ".meta"
        @documents_count = 0
      end
    
      def read
        @data = {}
        raw = IO.binread(@path)
        raw.unpack(ROW_PACK*(raw.bytesize / ROW_SIZE)).each_slice(3) do |term, count, position|
          term.delete!("\u0000")
          term.force_encoding("utf-8")
          @data[term] = [count, position]
          @documents_count += count
        end
      end
    
      def get(key)
        read if @data.nil?
        @data[key]
      end
      alias :[] :get
    
      def generate
        @buffer = []
        @write_offset = 0
        @index_file.header_reader.read do |term, count, position|
          @buffer << [term, count, position]
          flush if @buffer.size > 100_000
        end
        flush
      end
    
      private
      def flush
        IO.binwrite(@path, @buffer.flatten.pack(ROW_PACK*@buffer.size), @write_offset)
        @write_offset += ROW_SIZE*@buffer.size
        @buffer.clear
      end
    end  
  end
end
