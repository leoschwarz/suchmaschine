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
        @queue.delete(key)
        @items_count -= 1
      elsif @items_count+1>@max_items
        # Ältesten Eintrag löschen.
        @items.delete(@queue.shift)
        @items_count -= 1
      end
      
      @items_count += 1
      @queue.push(key)
      @items[key] = value
    end
    
    def include?(key)
      @items.has_key?(key)
    end
  end
end