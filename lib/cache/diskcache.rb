# TODO: Zur Zeit wird für jeden Schlüssel eine Datei erzeugt, dies könnte man eventuell besser lösen...

module Cache
  class DiskCache
    def self.get(key)
      file_path = cache_path(key)
      if File.exists? file_path
        File.read(file_path)
      else
        nil
      end
    end
    
    def self.set(key, value)
      file = File.open(cache_path(key), "w")
      file.write(value)
      file.close
    end
    
    private
    def self.cache_path(key)
      "cache/keyval/#{key}"
    end
  end
end