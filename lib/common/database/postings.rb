module Common
  module Database
    class Postings
      def initialize(word)
        @word      = word
        @temporary = temporary
        @metadata  = PostingsMetadata.load(word)
        @item_buffer = []
      end
      
      def rows_count
        @metadata.blocks.inject(:+).to_i
      end
      
      def blocks_count
        @metadata.blocks.count
      end
      
      def << (item)
        @item_buffer << item
      end
      
      def set_items (items)
        @item_buffer = items
      end
      
      def save
        while @item_buffer.size > 0
          block = @metadata.load_writeable_block
          items = @item_buffer.shift(block.free_rows)
          block.entries += items
          block.save
          @metadata.blocks[block.block_number] += items.size
        end
        
        @metadata.save
      end
      
      def self.temporary(word, load)
        PostingsBlock.temporary(word, load)
      end
    end
  end
end
