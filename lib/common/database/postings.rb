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
        load if options[:load]
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
      
      def delete_metadata
        @metadata.delete unless @metadata.nil?
      end
      
      def load
        @metadata = PostingsMetadata.load(@word, @temporary)
      end
      
      def loaded?
        !@metadata.nil?
      end
      
      # Schreibt den write_buffer in Blöcken nieder...
      def save
        if @metadata.nil?
          @metadata = PostingsMetadata.load(@word, @temporary)
        end
        
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
