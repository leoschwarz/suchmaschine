module Indexer
  class Merger
    def initialize(destination_writer, source_readers)
      @destination = destination_writer
      @sources     = source_readers
    end
    
    def merge
      while @sources.size > 0
        # Den Header auswählen der ins Ziel übernommen werden soll...
        headers = {}
        @sources.each do |source|
          type, term, n = source.current
          headers[term] ||= []
          headers[term] << [source, n]
        end
        term = headers.keys.min
        
        # Einen neuen Header in das Ziel schreiben
        sources = headers[term]
        n_total = sources.map{|source, n| n}.inject(:+)
        @destination.write_header(term, n_total)
        
        # Nun werden die einzelnen Quellen gemerged
        while sources.size > 0
          source, index = sources.each_with_index.min_by{|source, _| source[0].current[1]}
          
          type, freq, doc = source.current
          @destination.write_row(freq, doc)
          
          # Die Änderung nun vormerken...
          source.shift
          if source.current == nil
            # Quelle ist ganz fertig...
            @sources.delete(source)
          elsif source.current[0] == :header
            # Quelle ist in diesem Schritt fertig
            sources.delete_at(index)
          end          
        end      
      end
    end
  end
end
