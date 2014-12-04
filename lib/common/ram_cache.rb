############################################################################################
# Implementiert einen einfachen First-in-first-Out Cache für Objekte die unbestimmt lange  #
# Arbeitsspeicher gehalten werden sollen.                                                  #
# Wenn ein Objekt aus dem Cache entfernt wird, wird eine Methode namens                    #
# "removed_from_cache" aufgerufen, sofern diese definiert ist.                             #
# Mehr Informationen unter:                                                                #
# https://de.wikipedia.org/wiki/First_In_%E2%80%93_First_Out                               #
############################################################################################
module Common  
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
