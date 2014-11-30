module Common
  module IndexFile
    class RowReader
      def initialize(path, size)
        @path = path
        @size = size
      end
      
      # Liest n (count) Zeilen ausgehend von start und ruft den mitgegebenen Block auf...
      def read(start, count)
        raw = IO.binread(@path, count*IndexFile::ROW_SIZE, start)
        raw.unpack(IndexFile::ROW_PACK*count).each_slice(2) do |freq, doc|
          yield(freq, doc)
        end
      end
    end
  end
end
