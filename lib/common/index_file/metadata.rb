module Common
  module IndexFile
    class Metadata
      ROW_SIZE = 24
      ROW_PACK = "a20 L> L>"
      
      def initialize(index_file)
        @index_file = index_file
        @path       = index_file.path + ".meta"
      end
    
      def read
        @data = {}
        raw = IO.binread(@path)
        raw.unpack(ROW_PACK*(raw.bytesize / ROW_SIZE)).each_slice(2) do |term, count, position|
          @data[term] = [count, position]
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
