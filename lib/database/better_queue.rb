# Ziele:
# - Auch mit Gigabytes grossen Warteschlangen umgehen können.
# - Möglichst zufällige Reihenfolge der Einträge.
# - Zuverlässig (keine Einträge verlieren)
# - Trotzdem schnell sein.

# TODO: Eventuell das Verhalten auch in Randsituationen testen.
# TODO: Ein Problem tritt auf, da wenn ein Stapel eingelesen wird dies nur funktioniert, wenn auf dem Dateisystem
#       ein Stapel vorhanden ist. Bei neuen Warteschlangen ist dies jedoch nicht unbedingt der Fall und die
#       Warteschlange muss dann explizit gespeichert werden. (Also zbsp die Datenbank neustarten...)

module Database
  class BetterQueue
    MAX_BUFFER = 20_000
    
    def initialize(directory)
      @directory     = directory
      @insert_buffer = []
      @fetch_buffer  = []
      @metadata      = BetterQueueMetadata.load(File.join(directory, "metadata"))
    end
  
    def insert(line)
      @insert_buffer << line
      if @insert_buffer.size > MAX_BUFFER
        write_items
      end
    end
  
    def fetch
      if @fetch_buffer.size == 0
        unless fetch_items
          return nil
        end
      end
      
      @fetch_buffer.pop
    end
    
    def save
      @insert_buffer.concat(@fetch_buffer)
      write_items
      @metadata.save
    end
    
    private
    def write_items
      # Auf verschiedene Stapel verteilen, falls einer nicht genug Platz bietet.
      while @insert_buffer.size > 0
        batch = @metadata.get_random_fillable_batch
        if @insert_buffer.size - batch.empty_slots > 0
          appendable = batch.empty_slots
        else
          appendable = @insert_buffer.size
        end
        batch.insert(@insert_buffer.pop(appendable))
      end
    end
    
    def fetch_items
      batch = @metadata.get_random_readable_batch
      if batch.nil?
        false
      else
        @fetch_buffer = batch.read_all
        batch.delete
        true
      end
    end
  end
end
