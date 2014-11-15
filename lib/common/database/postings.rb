module Common
  module Database
    class Postings
      # word: das Stichwort
      # options[:temporary]: falls wahr werden die Daten nicht in der Datenbank gespeichert
      # options[:load]: falls wahr werden die Metadaten aus der Datenbank geladen
      def initialize(word, options={})
        options = {temporary: false, load: false}.merge(options)
        
        @word      = word
        @temporary = options[:temporary]
        fetch if options[:load]
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
        @metadata.blocks.map{|id,_| PostingsBlock.new(id, @temporary)}
      end
      
      # Löscht die alten Blöcke die zu diesem Postings gehören...
      def delete_blocks
        self.blocks.map{|block| block.delete}
        @metadata.blocks = []
      end
      
      def delete_metadata
        @metadata.delete unless @metadata.nil?
      end
      
      def fetch
        @metadata = PostingsMetadata.fetch(@word, @temporary)
      end
      
      def fetched?
        !@metadata.nil?
      end
      
      def sorted_blocks
        @metadata.sorted_blocks.map{|id,_| PostingsBlock.new(id, @temporary)}
      end
      
      def unsorted_blocks
        @metadata.unsorted_blocks.map{|id,_| PostingsBlock.new(id, @temporary)}
      end
      
      def mark_blocks_sorted
        @metadata.blocks_sorted = @metadata.blocks.count
      end
      
      # Schreibt den write_buffer in Blöcken nieder...
      def save
        @metadata ||= PostingsMetadata.fetch(@word, @temporary)
        
        @write_buffer.each_slice(PostingsBlock::MAX_ROWS) do |rows|
          block = PostingsBlock.new(nil, @temporary)
          block.entries = rows
          block.save
          @metadata.blocks << [block.id, block.rows_count]
        end
        
        @write_buffer.clear
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
