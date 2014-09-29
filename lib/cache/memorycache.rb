# Implementierung eines LRU-Cache Mechanismus
# https://de.wikipedia.org/wiki/Least_recently_used

module Cache
  class MemoryCache
    def initialize
      @data  = {}
      @queue = [] # erstes element = zuletzt benutzt, letztes element = am längsten nicht benutzt
    end
    
    def self.instance
      @@instance ||= MemoryCache.new
    end
    
    
    def get(key)
      if @data.has_key? key
        # Element an erste Stelle in der Warteschlange stellen
        @queue.delete(key)
        @queue.insert(0, key)
      else
        value = DiskCache.get(key)
        @data[key] = value
        @queue.insert(0, key)
        swap_if_needed
      end
      
      @data[key]
    end
    
    def set(key, value)
      if @data.has_key? key
        @data[key] = value
        @queue.delete(key)
        @queue.insert(0, key)
      else
        @data[key] = value
        @queue.insert(0, key)
        swap_if_needed
      end      
    end
    
    # Falls nötig werden die am längsten nicht gebrauchten Elemente in die Disk Datenbank verschoben...
    def swap_if_needed
      if @queue.size > Cache.config.memory_slots
        # Da dies nur aufgerufen wird wenn es sowieso höchstens ein weiteres Element geben kann,
        # kann man sich hier komplizierte Logik sparen.
        last_key = @queue.pop
        last_value = @data.delete(last_key)
        
        DiskCache.set(last_key, last_value)
      end
    end
    
    
    def self.get(key)
      instance.get(key)
    end
    
    def self.set(key, value)
      instance.set(key, value)
    end
  end
end