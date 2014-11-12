module Common
  module DatabaseClient
    class Postings
      def initialize(word, temporary=false)
        @word      = word
        @temporary = temporary
        @metadata  = PostingsMetadata.load(word)
        
        @item_buffer = []
      end
      
      def blocks_count
        @metadata.blocks.count
      end
      
      def << (item)
        @item_buffer << item
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
    end
  end
end
