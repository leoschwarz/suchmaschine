module Database
  class BetterQueueMetadata
    include ::Common::Serializable
    
    # Array mit Namen aller Stapel
    field :batches # Hash: Name => Anzahl Zeilen
    field :batch_counter, 0
    attr_accessor :path
    attr_accessor :directory
    
    # Gibt einen zufälligen Stapel zurück, der noch min. 75% frei ist.
    def get_random_fillable_batch
      # Falls es noch zu wenige Stapel hat, einen neuen erzeugen:
      if batches.size < 10
        return create_new_batch
      end
      
      # Alle Stapel durchsuchen
      batches.keys.shuffle.each do |name|
        batch = BetterQueueBatch.new(name, self)
        unless batch.full?
          return batch
        end
      end
      
      # Falls bis jetzt noch kein Stapel gefunden wurde, einen neuen erzeugen.
      create_new_batch
    end
    
    def get_random_readable_batch
      name = batches.keys.sample
      return nil if name.nil?
      BetterQueueBatch.new(name, self)
    end
    
    # Erzeugt einen neuen leeren Stapel und gibt diesen zurück.
    def create_new_batch
      self.batch_counter += 1
      BetterQueueBatch.new(batch_counter.to_s, self)
    end
    
    def self.load(path)
      if File.exist?(path)
        metadata = self.deserialize(File.read(path))
      else
        metadata = self.new({batches: {}})
      end
      
      metadata.path      = path
      metadata.directory = File.dirname(path)
      metadata
    end
    
    def save
      File.open(path, "w"){|file| file.write(self.serialize)}
    end
  end
end
