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
      
      # Fügt den write_buffer zu den Blöcken hinzu.
      # Falls es bereits einen unsortierten und noch nicht vollen Block gibt, wird dieser zunächst.
      # Ansonsten werden die Zeilen in der Reihenfolge niedergeschrieben und neue Blöcke erstellt.
      def save
        return nil if @write_buffer.nil? || @write_buffer.size == 0
        
        @metadata ||= PostingsMetadata.fetch(@word, @temporary)
        
        # Zuerst versuchen zum bestehenden Block soviel wie möglich vom Buffer zu speichern...
        last_unsorted_block = @unsorted_blocks[-1]
        if last_unsorted_block != nil && PostingsBlock::MAX_ROWS - @metadata.blocks[-1][1] > 0
          last_unsorted_block.fetch
          last_unsorted_block.append_entries(@write_buffer.shift(last_unsorted_block.rows_free))
          last_unsorted_block.save
          @metadata.blocks[-1][1] = last_unsorted_block.rows_count
        end
        
        # Neue Blöcke für die restlichen Einträge erstellen...
        while @write_buffer.size > 0
          block = PostingsBlock.new(nil, @temporary)
          block.entries = @write_buffer.shift(PostingsBlock::MAX_ROWS)
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
