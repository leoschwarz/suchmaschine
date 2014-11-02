module Common
  # Eine ganz einfache Implementierung eines Hashs mit Reihenfolge.
  # Implementiert nicht alle Methoden von Hash.
  class OrderedHash
    # pairs: 2 dimensionales Array
    def initialize(_pairs=[])
      @keys = _pairs.map{|k,v| k}
      @data = _pairs.to_h
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      if @data.has_key?(key)
        @data[key] = value
      else
        @keys << key
        @data[key] = value
      end
    end

    def keys
      @keys
    end

    def values
      @keys.map{|key| @data[key]}
    end
    
    def pairs
      keys.map{|key| [key, @data[key]]}.to_a
    end
    
    def clone
      self.new(pairs)
    end
  end
end
