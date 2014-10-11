module Common
  # Eine ganz einfache Implementierung eines Hashs mit Reihenfolge.
  # Implementiert nicht alle Methoden von Hash.
  class OrderedHash
    def initialize
      @keys = []
      @data = {}
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
  end
end
