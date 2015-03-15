############################################################################################
# Die BetterQueue ist eine Datenstruktur welche es ermöglicht eine grosse zufällige Warte- #
# schlange beständig auf der Festplatte zu speichern. Sie löste die alte BigQueue ab, die  #
# verschiedene Probleme hatte. Folgendes waren die Ziele bei der Implementierung:          #
# - Auch mit Gigabytes grossen Warteschlangen umgehen können.                              #
# - Möglichst zufällige Reihenfolge der Einträge.                                          #
# - Zuverlässig (keine Einträge verlieren)                                                 #
# - Trotzdem schnell sein.                                                                 #
# Hinweis: BetterQueue arbeitet mit dem Newline-Zeichen \n als Trennzeichen, was heisst,   #
# dass keine Einträge, welche dieses Zeichen enthalten verwendet werden können.            #
############################################################################################
require_relative './better_queue_metadata.rb'
require_relative './better_queue_batch.rb'
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
        # Da kein Stapel auf der Disk vorhanden ist, wird nun einfach versucht den
        # insert_buffer zu lesen, falls auch dies nicht gelingt, wird false zurückgegeben.
        if @insert_buffer.size > 0
          @fetch_buffer = @insert_buffer.shuffle
          @insert_buffer = []
          return true
        else
          return false
        end
      else
        @fetch_buffer = batch.read_all
        batch.delete
        return true
      end
    end
  end
end
