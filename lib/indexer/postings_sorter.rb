# Implementiert einen External Mergesort um die temporären Indexblöcke abschliessend zu sortieren.
# Literatur: http://dblab.cs.toronto.edu/courses/443/2014/07.sorting.html
# Ausführlichere Erläuterung: https://www.youtube.com/watch?v=Kg4bqzAqRBM

# TODO: Da hier wahrscheinlich noch Fehler lauern, würde ein ausführlicher Test
#       der Prozeduren nicht schaden...

module Indexer
  class PostingsBlockChain
    attr_reader :blocks
    
    def initialize(blocks=[])
      @blocks  = blocks
      @pointer = {block: 0, row: 0}
      @current_block = @blocks.shift
    end
    
    def fetch
      @current_block.fetch
    end
    
    def increase_pointer
      @pointer[:row] += 1
      if @pointer[:row] >= @current_block.rows_count
        @pointer[:row]    = 0
        @pointer[:block] += 1
        @current_block = @blocks.shift
        @current_block.fetch unless @current_block.nil?
      end
    end
    
    def current_row
      if @current_block
        @current_block.entries_cached[@pointer[:row]]
      else
        nil
      end
    end
    
    # Gibt eingeschlossen der aktuellen Zeile, alle noch verbleibenden Zeilen als Array zurück...
    def rows_left
      @current_block.entries_cached[@pointer[:row]..-1]
    end
    
    def delete_blocks
      @blocks.map{|block| block.delete}
    end
  end
  
  class PostingsBlockWriter
    MAX_ROWS = Indexer::PostingsBlock::MAX_ROWS
    
    attr_reader :blocks
    
    def initialize
      @buffer = []
      @blocks = []
    end
    
    def add_row(row)
      @buffer << row
      write if @buffer.size >= MAX_ROWS
    end
    
    def write
      block = Indexer::PostingsBlock.new
      block.bin_entries = @buffer
      block.save
      
      @blocks << Indexer::PostingsBlock.new(block.id)
      @buffer.clear
    end
  end
  
  class PostingsSorter
    # postings: Common::Database::Postings
    def initialize(postings)
      @postings = postings
    end
    
    def sort_blocks
      unsorted_blocks = @postings.unsorted_blocks
      if unsorted_blocks.size > 0        
        if unsorted_blocks.size != 1
          raise "Fehler: Der Indexierer muss verhindern, dass mehr als ein unsortierter Indexblock in den Sortierer gelangt."
        end
        
        if @postings.sorted_blocks.size == 0
          # In diesem Fall haben wir Glück, da es nur einen neuen Block gibt und noch keinen im Postings,
          # können wir schlichtweg den neuen Block hinzufügen und sind bereits fertig.
          @postings.add_block(unsorted_blocks[0])
          @postings.mark_blocks_sorted
          
          return
        end
        
        result = PostingsBlockWriter.new
        chains = [PostingsBlockChain.new(@postings.blocks), PostingsBlockChain.new(unsorted_blocks)]
        chains.map{|chain| chain.fetch}
        while chains.size == 2
          chain, i = chains.each_with_index.min_by{|chain, i| chain.current_row}
          
          result.add_row(chain.current_row)
          chain.increase_pointer
          if chain.current_row.nil?
            chains.delete_at(i)
          end
        end
        
        result.add_rows(chains[0].rows_left)
        
        # TODO der zweite block wird auch als sortiert markiert obwohl leer...
        @postings.delete_blocks
        result.blocks.each{|block| @postings.add_block(block)}
        @postings.mark_blocks_sorted
      end
    end
  end
end
