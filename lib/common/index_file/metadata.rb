############################################################################################
# Klasse für das Lesen und Schreiben von Metaindex-Dateien. Das Format der Metaindex-      #
# Dateien ist ganz einfach aufgebaut. Es werden jeweils zuerst die 24 Bytes der Header-    #
# Zeile aus der Index-Datei in eine Metaindex-Zeile geschrieben, und von einer 8 Bytes     #
# grossen Angabe der Position in der Index-Datei gefolgt.                                  #
############################################################################################
module Common
  module IndexFile
    class Metadata
      ROW_SIZE = 32
      ROW_PACK = "a20 L> Q> ".freeze

      def initialize(index_file)
        @index_file = index_file
        @meta_file_path = index_file.path + ".meta"
        @count_file_path = index_file.path + ".count"
      end

      def documents_count
        if File.exists?(@count_file_path)
          File.read(@count_file_path).to_i
        else
          0
        end
      end

      # Sucht nach einer Zeile in der Datei mithilfe einer Binärsuche, ohne den ganzen
      # Metaindex in den Arbeitsspeicher zu laden. Dies ist dann hilfreich, wenn man
      # mit einem grossem Metaindex arbeitet. (Unter Umständen kann dieser grösser
      # sein als das zur Verfügung stehende RAM, dabei will man aber noch weitere
      # Operationen mit dem Inhalt des Index durchführen.)
      # @return [Array, nil]
      def find(word)
        # Bestimme die Anzahl Zeilen in der Datei.
        rows_count = File.size(@meta_file_path) / ROW_SIZE

        # Lege zwei Begrenzungen fest.
        index_a = 0
        index_b = rows_count - 1

        # Solange die beiden Indezes nicht denselben Wert haben, sind wir nicht fertig.
        while index_a != index_b
          # Eine Zeile in der Mitte des Bereiches auswählen.
          index_middle = (index_a+index_b)/2
          current_row  = read_row(index_middle)

          # Gesuchtes Wort mit dem momentanen Stichwort vergleichen.
          if word < current_row[0]
            index_b = index_middle
          elsif word > current_row[0]
            index_a = index_middle
          elsif word == current_row[0]
            return current_row
          else
            # Der Eintrag existiert gar nicht.
            return nil
          end
        end

        return nil
      end

      # Generiert die Datei für die verwaltete Indexdatei.
      def generate
        @buffer = []
        @write_offset = 0
        @total = 0
        @index_file.header_reader.read do |term, count, position|
          @buffer << [term, count, position]
          @total += 1
          flush_write_buffer if @buffer.size > 100_000
        end
        flush_write_buffer

        # Totale Anzahl vermerken...
        File.open(@count_file_path, "w") do |file|
          file.write(@total.to_s)
        end
      end

      private
      # Liest den Inhalt einer bestimmten Zeile aus der Metaindex Datei.
      # @param index [Integer] Die wievielte Zeile ist es? (Kein Byte-offset!)
      # @return [Array] WORT (max 20 bytes), ZEILEN, POSITION (in der Indexdatei)
      def read_row(index)
        rawstr = IO.binread(@meta_file_path, ROW_SIZE, ROW_SIZE*index)
        row    = rawstr.unpack(ROW_PACK)

        # TODO : Diese Aufräumoperation extrahieren und irgendwo zentral lassen.
        #        Eventuell könnte man Ruby 2.1's neue Refinements hierzu verwenden und String patchen.
        row[0].delete!("\u0000")
        row[0].force_encoding("utf-8")
        row
      end

      # Schreibt den Puffer in die verwaltete Datei und löscht den Puffer.
      def flush_write_buffer
        IO.binwrite(@meta_file_path, @buffer.flatten.pack(ROW_PACK*@buffer.size), @write_offset)
        @write_offset += ROW_SIZE*@buffer.size
        @buffer.clear
      end
    end
  end
end
