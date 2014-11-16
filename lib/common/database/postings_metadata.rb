module Common
  module Database
    # TODO: Dokumentation etwas verschönern (-:
    class PostingsMetadata
      include Common::Serializable
      
      field :word
      
      # Wieviele der Blöcke sind sortiert. (0 = keine, .., 2= der erste und der zweite block sind so sortiert, dass der letzte eintrag vom ersten kleiner ist als der des zweiten, muss aber nicht für die darauffolgedenen Blöcke gelten...)
      field :blocks_sorted, 0
      
      # Array bestehend aus Arrays folgendes Formats:
      # [0] => ID
      # [1] => Anzahl Zeilen
      field :blocks
      
      attr_accessor :temporary
      
      def sorted_blocks
        self.blocks[0...blocks_sorted]
      end
      
      def unsorted_blocks
        self.blocks[blocks_sorted..-1]
      end
      
      def add_block(block)
        self.blocks << [block.id, block.rows_count]
      end
      
      def self.fetch(word, temporary=false)
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
      
      def self.batch_save(metadata_objects)
        Database.postings_metadata_batch_set(metadata_objects.map{|metadata| [metadata.word, metadata.serialize]})
      end
    end
  end
end
