require 'securerandom'

module Common
  module DatabaseClient
    # PostingsBlocks bilden die eigentlichen Postings Listen. Der blockbasierte Aufbau hat
    # zum Vorteil, dass das Sortieren der Listen einfacher wird, und das generell nicht mit
    # gigantischen Dateien hantiert werden muss. Ausserdem können bei der Abfrage auch nur
    # die Ergebnisse in einem ersten Block geladen werden, da diese wahrscheinlich die
    # relevantesten sein werden, bei Bedarf aber auch noch andere.
    #
    # Jeder Block erhält
    #
    # Die Sortierung der Zeilen erfolgt nach der Frequenz des Auftretens des Begriffes im
    # jeweiligen Dokument.
    #
    # Die einzelnen Zeilen folgen diesem Aufbau (big-endian Werte):
    # FREQUENCY   [4B  float]
    # WORDS       [4B  uinteger]
    # DOCUMENT_ID [16B hexadezimal/integer]
    class PostingsBlock
      ROW_SIZE   = 24
      MAX_ROWS   = 50_000
      BLOCK_SIZE = MAX_ROWS * ROW_SIZE
      PACK_INSTRUCTION = "h32 L> g"
      
      attr_reader :id
      
      def initialize(_id)
        @id  = _id
        @raw = ""
      end
      
      def bin_entries
        (0...rows_count).map{|i| @raw.byteslice(ROW_SIZE*i, ROW_SIZE)}
      end
      
      def bin_entries=(_bin_entries)
        @raw = _bin_entries.join("")
      end
      
      def entries
        self.bin_entries.map{|bin_row| bin_row.unpack(PACK_INSTRUCTION)}
      end
      
      def entries=(_entries)
        self.bin_entries = _entries.map{|row| row.pack(PACK_INSTRUCTION)}
      end
      
      def load
        @raw = Database.postings_get(@id)
      end
      
      def self.load(id)
        block = self.new(id)
        block.load
        block
      end
      
      def save
        Database.postings_set(@id, @raw)
      end
      
      def rows_count
        @raw.bytesize / ROW_SIZE
      end
      
      def rows_free
        MAX_ROWS - rows_count
      end
      
      private
      def generate_id
        SecureRandom.base64(24) # 32 Bytes
      end
    end
  end
end
