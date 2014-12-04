############################################################################################
# Die PointerReader Klasse ermöglicht das lesen von Index-Dateien, indem ein Zeiger immer  #
# an eine bestimmte Position zeigt. Es kann jeweils die aktuelle Zeile gelesen werden, bei #
# der es sich entweder um eine Header- oder eine Inhalt-Zeile handeln kann, oder es kann,  #
# sofern die Datei noch nicht zu Ende ist, den Pointer auf die folgende Zeile verschieben. #
# Hiermit wird es möglich nicht die gesammte Datei in den Arbeitsspeicher laden zu müssen, #
# muss aber nicht auf die Möglichkeit die gesammte Datei zu lesen verzichten.              #
############################################################################################
module Common  
  module IndexFile
    class PointerReader
      # TODO: Auslagern...
      MAX_ROWS = 5000
      
      def initialize(file_path, file_size)
        @file_path = file_path
        @file_size = file_size
        @read_offset = 0
        
        # Der erste Header wird bereits jetzt gelesen
        header = read_header
        @buffer = [header]
        # Die Anzahl an noch lesbarer Inhaltszeilen im momentanen Abschnitt
        @available_rows = header[2]
      end
    
      def current
        fetch_buffer if @buffer.empty?
        @buffer[0]
      end
    
      def shift
        @buffer.delete_at(0)
        fetch_buffer if @buffer.empty?
        @buffer[0]
      end
    
      private
      def fetch_buffer
        if @available_rows > MAX_ROWS
          # Nur ein Teil der Inhaltszeilen kann dieses mal geladen werden.
          @buffer = read_rows(MAX_ROWS)
          @available_rows -= MAX_ROWS
        elsif @available_rows > 0
          # Es können alle verbleibenden Zeilen geladen werden.
          @buffer = read_rows(@available_rows)
          @available_rows = 0
          # Falls möglich den nächsten Header lesen...
          if (header = read_header)
            @buffer << header
            @available_rows = header[2]
          else
            # Wir sind am Ende angelangt.
            @available_rows = 0
          end
        end
      end
      
      def binread(bytes)
        data = IO.binread(@file_path, bytes, @read_offset)
        @read_offset += bytes
        data
      end
      
      def read_header
        return nil if @read_offset >= @file_size
        term, count = binread(IndexFile::HEADER_SIZE).unpack(IndexFile::HEADER_PACK)
        [:header, term, count]
      end
      
      def read_rows(n)
        binread(IndexFile::ROW_SIZE*n).unpack(IndexFile::ROW_PACK*n).each_slice(2).map{|freq, doc| [:row, freq, doc]}
      end
    end
  end
end
