############################################################################################
# Diese Datei implemntiert die Logik, welche für die Zusammenführung verschiedener Index-  #
# Dateien miteinander notwendig ist.                                                       #
# Es werden Common::IndexFile::PointerReader verwendet, welche es ermöglichen in der Index #
# Datei zu navigieren, ohne die gesammte Datei in den Arbeitsspeicher laden zu müssen. So  #
# wird die Indexierung hier überhaupt erst möglich. Unter Umständen, kann es bei einem     #
# grossen Korpus notwendig sein, in der Konfiguration die Buffergrösse runterzuschrauben,  #
# da ansonsten zu wenig Arbeitsspeicher zur Verfügung stehen könnte.                       #
############################################################################################
module Indexer
  class Merger
    def initialize(destination_writer, source_readers)
      @destination = destination_writer
      @sources     = source_readers
    end
    
    def merge
      # Der Prozess ist abgeschlossen, sobald alle @sources entfernt wurden.
      while @sources.size > 0
        # Da in den verschiedenen Quellen verschiedene Stichworte für den momentanen Block
        # gegeben sein können, ist es zuerst nötig, Quellen auszuwählen, welche an der
        # momentanen Stelle dasselbe Stichwort verwenden.
        # Hierzu werden jeweils diejenigen ausgewählt, welche das Stichwort haben, welches
        # alphabetisch den geringsten Wert besitzt.
        sources_for_term = {}
        @sources.each do |source|
          type, term, count = source.current
          sources_for_term[term] ||= []
          sources_for_term[term] << [source, count]
        end
        term = sources_for_term.keys.min
        
        # Einen neuen Header in das Ziel schreiben
        sources = sources_for_term[term].map{|source, count| source}
        n_total = sources_for_term[term].map{|source, count| count}.inject(:+)
        
        @destination.write_header(term, n_total)
        
        # Den Zeiger der ausgewählten Quellen, jeweils auf Inhalt-Zeilen verschieben.
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
