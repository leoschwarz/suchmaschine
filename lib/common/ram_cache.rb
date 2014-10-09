module Common
  # Einfache in Memory Caches für Objekte.
  # 'max_items' gibt die maximale Anzahl Objekte an (nicht Bytes).

  # Least Recently Used Implementierung
  # https://de.wikipedia.org/wiki/Least_recently_used
  class RAMCacheLRU
    def initialize(max_items)
      @max_items   = max_items
      @items       = {}
      @items_count = 0
      @queue       = [] # Element #0 = Zuletzt benutzt, Element #-1 = Am längsten nicht benutzt.
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

  # First In First Out Implementierung
  # https://de.wikipedia.org/wiki/First_In_%E2%80%93_First_Out
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
