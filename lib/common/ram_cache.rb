module Common
  # Einfache in Memory Caches für Objekte.
  # 'max_items' gibt die maximale Anzahl Objekte an (nicht Bytes).
  
  # First in First Out Implementierung
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