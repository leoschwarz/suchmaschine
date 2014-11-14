module Common
  module Database
    class PostingsMetadata
      include Common::Serializable
      
      field :word
      
      # Array bestehend aus Arrays folgendes Formats:
      # [0] => id
      # [1] => rows
      field :blocks
      # TODO: Dieses Feld ging bis jetzt noch ein bisschen in Vergessenheit
      field :total_occurences, 0
      
      attr_accessor :temporary
      
      def add_block(block)
        self.blocks << [block.id, block.rows_count]
      end
      
      def self.load(word, temporary=false)
        if !temporary && (data = Database.postings_metadata_get(word)) != nil
          metadata = self.deserialize(data)
        else
          metadata = self.new({word: word, blocks:[]})
        end
        
        metadata.temporary = temporary
        metadata
      end
      
      def save
        unless self.temporary
          Database.postings_metadata_set(self.word, self.serialize)
        end
      end
    end
  end
end
