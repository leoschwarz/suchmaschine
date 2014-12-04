############################################################################################
# Implmentiert einfache Caches für Objekte die im RAM gehalten werden sollen. Sobald ein   #
# Element nicht mehr im RAM gehalten werden kann, wird es aus diesem gelöscht und falls es #
# eine Methode namens "removed_from_cache" besitzt, wird diese aufgerufen.                 #
# Die Implementierung orientiert sich an folgenden Wikipedia-Artikeln:                     #
# - https://de.wikipedia.org/wiki/Least_recently_used                                      #
# - https://de.wikipedia.org/wiki/First_In_%E2%80%93_First_Out                             #
############################################################################################
# TODO werden beide benötigt? Wenn nicht entfernen.
module Common
  # Implementierung eines Least-recently-used Caches.
  class RAMCacheLRU
    def initialize(max_items)
      @max_items   = max_items
      @items       = {}
      @items_count = 0
      # Das erste Element ist das am kürzlichsten benutzte,
      # Das letzte Element ist das am längsten unbenutzte.
      @queue       = []
    end

    # Wert für Schlüssel entnehmen.
    def [](key)
      if @items.has_key?(key)
        # Element an die erste Stelle in die Warteschlange verschieben
        @queue.delete(key)
        @queue.insert(0, key)
        @items[key]
      else
        nil
      end
    end

    # Wert für Schlüssel setzen.
    def []=(key, value)
      if @items.has_key?(key)
        @queue.delete(key)
        @queue.insert(0, key)
        @items[key].removed_from_cache if item.respond_to? :removed_from_cache
        @items[key] = value
      else
        @queue.insert(0, key)
        @items[key] = value
        @items_count += 1

        if @items_count > @max_items
          delete_LRU
        end
      end
    end

    def delete(key)
      raise NotImplementedError
    end

    def include?(key)
      @items.has_key?(key)
    end

    def remove_all
      while @items_count > 0
        delete_LRU
      end
    end

    private
    def delete_LRU
      @items_count -= 1
      item = @items.delete(@queue.pop)
      item.removed_from_cache if item.respond_to? :removed_from_cache
    end
  end
  
  # Implementierung eines First-in-first-out Caches.
  class RAMCacheFIFO
    def initialize(max_items)
      @max_items   = max_items
      @items       = {}
      @items_count = 0
      @queue       = []
    end

    def [](key)
      @items[key]
    end

    def []=(key, value)
      if self.include?(key)
        # Schlüssel aus der Warteschlange nehmen.
        self.delete(key)
      elsif @items_count+1>@max_items
        # Ältesten Eintrag löschen.
        self.delete(@queue[0])
      end

      @items_count += 1
      @queue.push(key)
      @items[key] = value
    end

    def delete(key)
      @queue.delete(key)
      item = @items.delete(key)
      item.removed_from_cache if item.respond_to? :removed_from_cache
      @items_count -= 1
    end

    def include?(key)
      @items.has_key?(key)
    end

    def remove_all
      @items.keys.each do |key|
        self.delete(key)
      end
    end
  end
end
