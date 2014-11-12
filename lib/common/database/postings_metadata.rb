module Common
  module Database
    class PostingsMetadata < Common::SerializableObject
      field :word
      
      # Array bestehend aus Arrays folgendes Formats:
      # [0] => id
      # [1] => rows
      field :blocks
      field :total_occurences, 0
      
      attr_accessor :temporary
      
      def add_block(block)
        self.blocks << [block.id, block.rows_count]
      end
      
      def self.load(word, temporary=false)
        data = Database.postings_metadata_get(word, temporary)
        if data.nil?
          metadata = self.new({word: word, blocks:[]})
        else
          metadata = self.deserialize(data)
        end
        metadata.temporary = temporary
        metadata
      end
      
      def save
        Database.postings_metadata_set(self.word, self.serialize, self.temporary)
      end
    end
  end
end
