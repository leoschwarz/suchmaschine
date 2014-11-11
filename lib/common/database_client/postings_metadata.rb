module Common
  module DatabaseClient
    # Ein PostingsMetadata-Eintrag listet auf, wo in den Postings Einträgen eines Wortes,
    # welche Information zu finden sind.
    #
    # Dabei wird jeweils die erste Zeile eines jeden Posting Eintragblocks gespeichert.
    #
    # Der Beginn des Eintrages folgt diesem Aufbau (big-endian Wert):
    # - TOTAL_OCCURENCES [8B uinteger]
    #
    # Die einzelnen Zeilen folgen diesem Aufbau (big-endian Werte):
    # - FIRST_ROW    [24B binary]: Erste Reihe des Datensatzes
    # - BLOCK_NUMBER [4B integer]
    # - LENGTH       [4B integer]: Länge des Abschnittes (kann auch evtl kürzer sein)
    class PostingsMetadata
      ROW_SIZE = 32
      
      attr_accessor :total_occurences
      attr_accessor :rows
      
      def initialize(word, raw_string="")
        @word = word
        @raw_string = raw_string
        
        deserialize
      end
      
      def self.load(word)
        PostingsMetadata.new(word, Database.postings_metadata_get(word))
      end
      
      def save
        serialize
        Database.postings_metadata_set(word)
      end
      
      private
      def deserialize
        @total_occurences = 0
        @rows = []
        
        if @raw_string.bytesize >= 8
          @total_occurences = @raw_string.byteslice(0,8).unpack("Q>")[0]
          
          rows_count = (@raw_string.bytesize-8) / ROW_SIZE
          (0...rows_count).each do |i|
            first_row = @raw_string.byteslice(8+i*ROW_SIZE, 24)
            block_n, length = @raw_string.byteslice(8+i*ROW_SIZE+24, 8).unpack("L> L>")
            @rows << [first_row, block_n, length]
          end
        end
      end
      
      def serialize
        @raw_string = ""
        @raw_string << [@total_occurences].pack("Q>")
        
        @rows.each do |row|
          @raw_string << row[0]
          @raw_string << row[1..2].pack("L> L>")
        end
      end
    end
  end
end
