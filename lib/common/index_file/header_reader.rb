############################################################################################
# Die HeaderReader Klasse ermöglicht das effiziente Lesen der Header-Zeilen eines Index-   #
# Dokumentes. Die restlichen Zeilen werden nicht gelesen, sondern direkt übersprungen, um  #
# den Lesevorgang zu beschleunigen. Diese Implementierung verwendet keinen Puffer, weshalb #
# dies nur in Kombination mit Lauwerken mit sehr kurzer Zugriffszeit verwendet werden      #
# sollte, da das Lesen sonst ineffizient sein könnte.                                      #
############################################################################################
module Common
  module IndexFile
    class HeaderReader
      def initialize(file_path, file_size)
        @file_path = file_path
        @file_size = file_size
      end
    
      # Diese Methode liest die Datei und erwartet einen Block als Parameter, der für jede
      # Header-Zeile aufgerufen wird.
      def read        
        pointer = 0
        while pointer < @file_size
          raw = IO.binread(@file_path, IndexFile::HEADER_SIZE, pointer)
          term, count = raw.unpack(IndexFile::HEADER_PACK)
          pointer += IndexFile::HEADER_SIZE
          yield(term, count, pointer) # <-- callback
          pointer += count * IndexFile::ROW_SIZE
        end
      end
    end
  end
end
