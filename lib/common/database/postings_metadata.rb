module Common
  module Database
    class PostingsMetadata < Common::SerializableObject
      field :word
      field :blocks # Anzahl Zeilen in den einzelnen Blöcken...
      field :total_occurences, 0
      
      def self.load(word)
        data = Database.postings_metadata_get(word)
        if data.nil?
          self.new({word: word, blocks:[]})
        else
          self.deserialize(data)
        end
      end
      
      def save
        Database.postings_metadata_set(self.word, self.serialize)
      end
      
      # Gibt einen Block zurück, der noch neue Einträge aufnehmen kann,
      # falls kein Block gefunden wurde, wird ein neuer erzeugt.
      def load_writeable_block
        if self.blocks.size == 0 || self.blocks[-1] >= PostingsBlock::ROW_SIZE
          # Es muss ein neuer Block erzeugt werden...
          self.blocks << 0
          PostingsBlock.new(self.word, self.blocks.size - 1)
        else
          # Der letzte Block 
          PostingsBlock.load(self.word, self.blocks.size - 1)
        end
      end
    end
  end
end
