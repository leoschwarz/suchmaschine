module Indexer
  class Merger
    def initialize(destination_writer, source_readers)
      @destination = destination_writer
      @sources     = source_readers
    end
    
    def merge
      # Der Prozess ist abgeschlossen, sobald alle @sources entfernt wurden.
      while @sources.size > 0
        # Da nun in den verschiedenen Quellen ein unterschiedliches Stichwort zuoberst sein kann,
        # muss zuerst dasjenige gefunden werden, welches alphabetisch den geringsten Wert bestitzt.
        sources_for_term = {}
        @sources.each do |source|
          type, term, n = source.current
          sources_for_term[term] ||= []
          sources_for_term[term] << [source, n]
        end
        term = sources_for_term.keys.min
        
        # Einen neuen Header in das Ziel schreiben
        sources = sources_for_term[term].map{|source, count| source}
        n_total = sources_for_term[term].map{|source, count| count}.inject(:+)
        
        @destination.write_header(term, n_total)
        
        # Den Pointer der ausgewählte Quellen jeweils um eins weiter verschieben, sodass auf eine Inhaltszeile gezeigt wird.
        sources.each do |source|
          while source.current[0] == :header
            source.shift
          end
        end
        
        # Nun werden die einzelnen Quellen gemerged
        while sources.size > 0
          source, index = sources.each_with_index.min_by{|source, _| source.current[1]}
          
          type, freq, doc = source.current
          @destination.write_row(freq, doc)
          
          # Die Änderung nun vormerken...
          source.shift
          if source.current == nil
            # Quelle ist ganz fertig...
            sources.delete_at(index)
            @sources.delete(source)
          elsif source.current[0] == :header
            # Quelle ist in diesem Schritt fertig
            sources.delete_at(index)
          end          
        end      
      end
      
      @destination.flush
    end
  end
end
