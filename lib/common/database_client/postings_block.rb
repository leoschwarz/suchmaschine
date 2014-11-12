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
    # FREQUENCY   [4B  float]
    # WORDS       [4B  uint32]
    # DOCUMENT_ID [16B hexadezimal/integer]
    class PostingsBlock
      ROW_SIZE   = 24
      BLOCK_SIZE = 50_000 * ROW_SIZE
      PACK_INSTRUCTION = "h32 L> g"
      
      attr_reader :word, :block_number
      
      def initialize(word, block_number, options={})
        options = {raw_string: "", temporary: false, temporary_path: nil, temporary_load: false}.merge(options)
        
        @word = word
        @block_number = block_number
        @raw_string     = options[:raw_string]
        @temporary      = options[:temporary]
        @temporary_path = options[:temporary_path]
        
        if options[:temporary] && options[:temporary_load]
          @raw_string = File.read(@temporary_path)
        end
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
        Postings.new(word, block_number, raw_string: Database.postings_get(word, block_number))
      end
      
      def self.temporary(word, load=false, path=nil)
        path ||= Config.paths.index_tmp + word
        postings = Postings.new(word, nil, temporary: true, temporary_path: path, temporary_load: load)
      end
      
      def save
        if @temporary
          File.open(@temporary_file, "w") do |file|
            file.write(@raw_string)
          end
        else
          Database.postings_set(@word, @block_number, @raw_string)
        end
      end
      
      def rows_count
        @raw_string.bytesize / ROW_SIZE
      end
      
      def free_rows
        (BLOCK_SIZE - @raw_string.bytesize) / ROW_SIZE
      end
      
      def full?
        free_rows == 0
      end
    end
  end
end
