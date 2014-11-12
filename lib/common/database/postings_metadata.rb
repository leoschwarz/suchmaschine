module Common
  module Database
    class PostingsMetadata < Common::SerializableObject
      field :word
      
      # Array bestehend aus Arrays folgendes Formats:
      # [0] => id
      # [1] => rows
      field :blocks
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
    end
  end
end
