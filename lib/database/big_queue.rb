module Database
  class BigQueue
    def initialize(directory)
      # Initialisierung
      @directory = directory
      @metadata = BigQueueMetadata.open_directory(directory)
      @metadata = BigQueueMetadata.new(File.join(directory, "metadata.json")) if @metadata.nil?
      
      # Eine BigQueueBatch Instanz für einen vollen Stapel erzeugen, falls möglich.
      if @metadata.full_batches.size > 0
        load_random_full_batch
      end
      
      # Eine BigQueueBatch Instanz für den momentan zu befüllenden Stapel erzeugen.
      if @metadata.open_batch.nil?
        @metadata.open_batch = @metadata.next_batchname
        @metadata.save
      end
      @open_batch = BigQueueBatch.new(batch_path(@metadata.open_batch))
    end
    
    # Schreibt eine URL in das System.
    def insert(url)
      # Neuen Stapel laden, falls der alte voll ist.
      if @open_batch.full?
        @metadata.full_batches << @metadata.open_batch
        @metadata.open_batch = @metadata.next_batchname
        @metadata.save
        @open_batch.save
        @open_batch = BigQueueBatch.new(batch_path(@metadata.open_batch))
      end
      
      # Eintrag hinzufügen
      @open_batch.insert(url)
    end
    
    # Nimmt eine URL aus dem System.
    def fetch
      if @full_batch.nil?
        return nil
      end
      
      if @full_batch.empty?
        # Den Stapel löschen und den Eintrag aus metadata.json löschen und versuchen einen neuen zu laden.
        @full_batch.delete
        @metadata.full_batches.delete_at(@full_batch_index)
        @metadata.save
        if @metadata.full_batches.empty?
          # Es gibt keinen weiteren vollen Stapel
          @full_batch_index = nil
          @full_batch = nil
          return nil
        else
          load_random_full_batch
        end
      end
      
      @full_batch.fetch
    end
    
    # Speichert alles zu speichernde
    def save_everything
      @full_batch.save unless @full_batch.nil?
      @open_batch.save
      @metadata.save
    end
    
    private
    def batch_path(name)
      File.join(@directory, "batch:#{name}")
    end
    
    def load_random_full_batch
      @full_batch_index = rand(0...@metadata.full_batches.size)
      @full_batch = BigQueueBatch.new(batch_path(@metadata.full_batches[@full_batch_index]))
    end
  end
end