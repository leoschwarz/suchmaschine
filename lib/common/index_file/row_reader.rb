############################################################################################
# Die RowReader Klasse ist das Gegenstück zum HeaderReader. Ausgehend ab einer bestimmten  #
# Positon in der Index-Datei, kann eine bestimmte Anzahl an Inhalt-Zeilen gelesen werden.  #
############################################################################################
module Common
  module IndexFile
    class RowReader
      def initialize(path, size)
        @path = path
        @size = size
      end
      
      # Liest Inhalt-Zeilen ausgehend einer bestimten Position und ruft den mitgegebenen
      # Block für jede Inhalt-Zeile mit den Parametern TF und Dokument-ID auf. 
      # @param start [Integer] Relative Position der Einträge in der Index-Datei.
      # @param count [Integer] Anzahl der Zeilen die gelesen werden soll.
      def read(start, count)
        raw = IO.binread(@path, count*IndexFile::ROW_SIZE, start)
        raw.unpack(IndexFile::ROW_PACK*count).each_slice(2) do |freq, doc|
          yield(freq, doc)
        end
      end
    end
  end
end
