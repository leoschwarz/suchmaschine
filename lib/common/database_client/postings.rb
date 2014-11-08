module Common
  module DatabaseClient
    # Ein Postings Eintrag listet alle bekannten Dokumente (Postings) eines Stichwortes auf.
    # Da solche Einträge, bei bestimmten Stichwörtern sehr gross werden können, werden diese
    # in einzelne Blöcke aufgeteilt, welche dann aus der Datenbank abgerufen werden können.
    #
    # Die einzelnen Zeilen sind nach der Frequenz des Auftretens des Begriffes sortiert,
    # daher kann man bei weiteren Operationen annehmen, dass die für den Begriff relevantesten
    # Einträge, sich jeweils im allerersten Block finden lassen werden.
    #
    # Die einzelnen Zeilen folgen diesem Aufbau (big-endian Werte):
    # FREQUENCY   [4B  big-endian float]
    # DOCUMENT_ID [16B big-endian hexadezimal/integer]
    class Postings
      ROW_SIZE   = 20
      BLOCK_SIZE = 50_000 * ROW_SIZE
      PACK_INSTRUCTION = "h32 g"
      
      def initialize(word, block_number, rawstring="")
        @word = word
        @block_number = block_number
        @raw_string = rawstring
      end
      
      def bin_entries
        count = @raw_string.bytesize / ROW_SIZE
        (0...count).map{|i| @raw_string.byteslice(ROW_SIZE*i, ROW_SIZE)}
      end
      
      def bin_entries=(bin_entries)
        @raw_string = bin_entries.join("")
      end
      
      def entries
        self.bin_entries.map{|bin_row| bin_row.unpack(PACK_INSTRUCTION)}
      end
      
      def entries=(entries)
        self.bin_entries = entries.map{|row| row.pack(PACK_INSTRUCTION)}
      end
      
      def self.load(word, block_number)
        # TODO
      end
      
      def save
        # TODO
      end
    end
  end
end
