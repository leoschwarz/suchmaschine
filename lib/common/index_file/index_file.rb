############################################################################################
# Diese Datei lädt das Common::IndexFile Modul, welches mit der new Methode die IndexFile  #
# Klasse bereit stellt. Diese stellt eine einfache Schnittstelle zu anderen Klassen zur    #
# Verfügung, welche das einfache schreiben und lesen von Index-Dateien ermöglichen.        #
#                                                                                          #
# Die Index Dateien besitzen ein eigenens binäres Format:                                  #
# [WORT-20] = 20 Bytes langes Stichwort (am Ende mit Nullbytes aufgefüllt).                #
# [FREQ-04] = 4  Bytes lange  Fliesskommazahl welche die Termfrequenz im Dokument angibt.  #
# [DOKU-16] = 16 Bytes lange  Hexadezimalzahl/String zur Kennzeichnung des Dokumentes.     #
# [ANZA-04] = 4  Bytes lange  Integerzahl welche die Anzahl Dokumente für das              #
#                             entsprechende Stichwort auflistet.                           #
#                                                                                          #
# Die Elemente liegen immer in einer der beiden Annordnungen vor:                          #
# - [WORT-20][ANZA-04] : Header-Zeile                                                      #
# - [FREQ-04][DOKU-16] : Inhalt-Zeile                                                      #
############################################################################################
module Common
  module IndexFile
    class IndexFile
      HEADER_PACK = "a20 L>".freeze
      ROW_PACK    = "g h32".freeze
      HEADER_SIZE = 24
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

      def exists?
        @exists
      end

      def delete
        File.unlink(@path) if File.exist?(@path)
        File.unlink(@path+".meta") if File.exist?(@path+".meta")
        reload
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
        @_metadata
      end
    end

    # Methode des Moduls um eine neue Instanz von Common::IndexFile::IndexFile zu erzeugen...
    def self.new(path)
      ::Common::IndexFile::IndexFile.new(File.expand_path path)
    end
  end
end
