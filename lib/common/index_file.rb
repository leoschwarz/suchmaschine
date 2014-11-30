require_relative './index_file/header_reader.rb'
require_relative './index_file/metadata.rb'
require_relative './index_file/pointer_reader.rb'
require_relative './index_file/row_reader.rb'
require_relative './index_file/writer.rb'

module Common
  module IndexFile
    # Diese Klasse stellt eine einfache Schnittstelle zu anderen Klassen zur Verfügung,
    # welche das einfache schreiben und lesen von Index-Dateien ermöglichen.
    #
    # Die Index Dateien besitzen ein eigenens spezielles binäres Format:
    # [WORT-20] = 20 Bytes langes Stichwort (Nullybytes werden am Ende hinzugefügt, falls das Stichwort kürzer ist).
    # [FREQ-04] = 4  Bytes lange  Fliesskommazahl welche die Termfrequenz im Dokument angibt.
    # [DOKU-16] = 16 Bytes lange  Hexadezimalzahl/String zur Kennzeichnung des Dokumentes.
    # [ANZA-04] = 4  Bytes lange  Integerzahl welche die Anzahl Dokumente für das entsprechende Stichwort auflistet.
    #
    # Die Elemente liegen immer in einer der beiden Annordnungen vor:
    # - [FREQ-04][WORT-20][ANZA-04] : Dies markiert einen neuen Abschnitt für ein Stichwort,
    #                                 das Feld der Frequenz wird auf 0 gesetzt um diesen Abschnitt zu markieren.
    # - [FREQ-04][DOKU-16]          : Es gibt jeweils für jedes Auftreten pro Dokument eine solche Zeile,
    #                                 das Feld der Frequenz wird immer auf einen Wert ≠ 0 gesetzt um diesen Abschnit zu markieren.
    class IndexFile
      HEADER_PACK = "g a20 L>"
      ROW_PACK    = "g h32"
      HEADER_SIZE = 28
      ROW_SIZE    = 20
    
      attr_accessor :path
    
      def initialize(path)
        @path = path
        reload
      end
      
      def reload
        @exists = File.exists?(@path)
        if @exists
          @size = File.size(@path)
        else
          @size = 0
        end
      end
    
      def header_reader
        HeaderReader.new(@path, @size)
      end
    
      def pointer_reader
        PointerReader.new(@path, @size)
      end
      
      def row_reader
        RowReader.new(@path, @size)
      end
    
      def writer(buffer_max=1024*1024)
        Writer.new(@path, @size, buffer_max)
      end
    
      def metadata
        @_metadata ||= Metadata.new(self)
      end
    end
    
    # Methode des Moduls um eine neue Instanz von Common::IndexFile::IndexFile zu erzeugen...
    def self.new(path)
      ::Common::IndexFile::IndexFile.new(File.expand_path path)
    end
  end
end
