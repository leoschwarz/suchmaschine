############################################################################################
# Die IndexFile::Writer Klasse ermöglicht das einfache Schreiben von Index-Dateien.        #
# Die Schreibzugriffe werden gebuffert, es ist aber dennoch effizienter die write_rows     #
# Methode für das Schreiben vieler Zeilen zu verwenden, da diese einen einzelnen "pack"    #
# Methoden-Aufruf vollstreckt, anstatt viele einzelne für jede separate Zeile.             #
############################################################################################
module Common
  module IndexFile
    class Writer
      def initialize(path, size, buffer_max)
        @path   = path
        @size   = size
        @buffer = ""
        @buffer_max = buffer_max
      end

      def write_header(word, n)
        @buffer << [word, n].pack(IndexFile::HEADER_PACK)
        flush if @buffer.bytesize > @buffer_max
      end

      def write_row(freq, doc)
        @buffer << [freq, doc].pack(IndexFile::ROW_PACK)
        flush if @buffer.bytesize > @buffer_max
      end

      def write_rows(pairs)
        @buffer << pairs.flatten.pack(IndexFile::ROW_PACK * pairs.size)
        flush if @buffer.bytesize > @buffer_max
      end

      def flush
        # @size <=> offset
        IO.binwrite(@path, @buffer, @size)
        @size += @buffer.bytesize
        @buffer.clear
      end
    end
  end
end
