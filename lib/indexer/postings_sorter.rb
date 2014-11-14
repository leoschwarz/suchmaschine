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
    
    def delete_blocks
      @blocks.map{|block| block.delete}
    end
  end
  
  class PostingsBlockWriter
    MAX_ROWS = Indexer::PostingsBlock::MAX_ROWS
    
    attr_reader :blocks
    
    def initialize(temporary)
      @temporary = temporary
      @buffer = []
      @blocks = []
    end
    
    def add_row(row)
      @buffer << row
      write if @buffer.size >= MAX_ROWS
    end
    
    def write
      loaded_block = Indexer::PostingsBlock.new(nil, temporary: @temporary)
      loaded_block.bin_entries = @buffer
      loaded_block.save
      
      @blocks << Indexer::PostingsBlock.new(loaded_block.id, temporary: @temporary)
      @buffer.clear
    end
    
    def to_chain
      PostingsBlockChain.new(@blocks)
    end
  end
  
  class PostingsSorter
    # postings: Common::Database::Postings
    def initialize(postings)
      @postings = postings
    end
    
    def sort_blocks
      # Jeden Block in eine eigene Kette laden...
      @postings.fetch unless @postings.fetched?
      all_chains = @postings.blocks.map{|block| PostingsBlockChain.new([block])}
      
      # Nun werden jeweils fünf Ketten umsortiert, bis es nur noch eine Kette gibt...
      while all_chains.size > 1
        all_chains = all_chains.each_slice(5).map do |chains|
          chains.map{|c| c.fetch}
        
          result = PostingsBlockWriter.new(true)
          while chains.size > 1
            # Das minimum finden:
            min_chunk, min_i = chains.each_with_index.min_by{|chunk, i| chunk.current_row}
            
            result.add_row(min_chunk.current_row)
            min_chunk.increase_pointer
            if min_chunk.current_row.nil?
              chains.delete_at(min_i)
            end
          end
          
          while chains[0].current_row != nil
            result.add_row(chains[0].current_row)
            chains[0].increase_pointer
          end
        
          result.write
          result.to_chain
        end
      end
      
      # Nun gibt es nur noch eine grosse sortierte Kette, welche zurückgegeben werden kann...
      @postings.delete_blocks
      
      result = all_chains[0]
      result.fetch
      result.blocks.each{|block| @postings.add_block(block)}
    end
  end
end
