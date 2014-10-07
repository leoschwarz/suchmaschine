module Database
  class BigQueue
    def initialize(directory)
      # Metainformation laden.
      @directory = directory
      @metadata   = BigQueueMetadata.open_directory(directory)
      @metadata ||= BigQueueMetadata.new(File.join(directory, "metadata.json"))
    end
    
    # Schreibt einen Eintrag in die Warteschlange.
    def insert(item)
      load_open_batch
      @open_batch.insert(item)
    end
    
    # Nimmt einen Eintrag aus der Warteschlange.
    def fetch
      load_full_batch
      return nil if @full_batch.nil?    
      @full_batch.fetch
    end
    
    # Speichert alles zu speichernde
    def save_everything
      @full_batch.save unless @full_batch.nil?
      @open_batch.save unless @open_batch.nil?
      @metadata.save
    end
    
    private
    def batch_path(name)
      File.join(@directory, "batch:#{name}")
    end
    
    def load_full_batch
      if @full_batch.nil? || @full_batch.empty?
        # Falls bereits ein Stapel existiert, dieser aber leer ist, muss dieser gelöscht werden.
        unless @full_batch.nil?
          @full_batch.delete
          @metadata.full_batches.delete_at(@full_batch_index)
          @metadata.save
          @full_batch_index = nil
          @full_batch = nil
        end
        
        # Neuen Stapel laden, falls möglich
        if @metadata.full_batches.size > 0
          @full_batch_index = rand(0...@metadata.full_batches.size)
          @full_batch = BigQueueBatch.new(batch_path(@metadata.full_batches[@full_batch_index]))
        end
      end
    end
    
    def load_open_batch
      if @open_batch.nil?
        # Es ist noch kein Stapel geöffnet.
        if @metadata.open_batch.nil?
          @metadata.open_batch = @metadata.next_batchname
          @metadata.save
        end
        @open_batch = BigQueueBatch.new(batch_path(@metadata.open_batch))
      else
        # Es ist bereits ein Stapel geöffnet,
        # falls dieser voll ist: Speichern + neuen Stapel laden
        if @open_batch.full?
          @metadata.full_batches << @metadata.open_batch
          @metadata.open_batch = @metadata.next_batchname
          @metadata.save
          @open_batch.save
          @open_batch = BigQueueBatch.new(batch_path(@metadata.open_batch))
        end
      end
    end
  end
end
