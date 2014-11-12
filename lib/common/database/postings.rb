module Common
  module Database
    class Postings
      def initialize(word, options={})
        options = {temporary: false, load: false}.merge(options)
        
        if options[:temporary]
          word = "temp:"+word
        end
        
        @word      = word
        @metadata  = PostingsMetadata.load(@word) if options[:load]
        @write_buffer = []
      end
      
      def temporary?
        @temporary
      end
      
      def blocks_count
        @metadata.blocks.count
      end
      
      def rows_count
        @metadata.blocks.map{|_,block_rows| block_rows}.inject(:+).to_i
      end
      
      def add_row(row)
        @write_buffer << row
      end
      
      def add_rows(rows)
        @write_buffer.concat(rows)
      end
      
      # Löscht die alten Blöcke die zu diesem Postings gehören...
      def delete_blocks
        @metadata.blocks.map{|id,count| PostingsBlock.new(id).delete}
        @metadata.blocks = []
      end
      
      # Schreibt den write_buffer in Blöcken nieder...
      def save
        @write_buffer.each_slice(PostingsBlock::MAX_ROWS) do |rows|
          block = PostingsBlock.new
          block.entries = rows
          block.save
          @metadata.blocks << [block.id, block.rows_count]
        end
        @metadata.save
      end      
    end
  end
end
