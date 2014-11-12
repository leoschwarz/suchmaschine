module Common
  module Database
    class Postings
      def initialize(word, options={})
        options = {temporary: false, load: false}.merge(options)
        
        @word      = word
        @temporary = options[:temporary]
        @metadata  = PostingsMetadata.load(@word, @temporary) if options[:load]
        @write_buffer = []
      end
      
      def blocks_count
        @metadata.blocks.count
      end
      
      def rows_count
        @metadata.blocks.map{|_,block_rows| block_rows}.inject(:+).to_i
      end
      
      def add_block(block)
        @metadata.add_block(block)
      end
      
      def add_row(row)
        @write_buffer << row
      end
      
      def add_rows(rows)
        @write_buffer.concat(rows)
      end
      
      def blocks
        @metadata.blocks.map{|id,_| PostingsBlock.new(id, temporary: @temporary)}
      end
      
      # Löscht die alten Blöcke die zu diesem Postings gehören...
      def delete_blocks
        @metadata.blocks.map{|id,count| PostingsBlock.new(id, @temporary).delete}
        @metadata.blocks = []
      end
      
      # Schreibt den write_buffer in Blöcken nieder...
      def save
        @write_buffer.each_slice(PostingsBlock::MAX_ROWS) do |rows|
          block = PostingsBlock.new(nil, @temporary)
          block.entries = rows
          block.save
          @metadata.blocks << [block.id, block.rows_count]
        end
        @metadata.save
      end
      
      def insert_from(other_posting)
        other_posting.blocks.each do |block|
          add_block(block)
        end
      end
    end
  end
end
