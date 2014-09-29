require 'singleton'
require 'digest/md5'

module Database
  class StorageDisk
    include Singleton
    
    def initialize
      @current_size = 0
      
      # Dateien auszählen
      Dir["#{root_path}/*"].each do |file|
        @current_size += File.size(file)
      end
    end
    
    # Pfad zum Stammverzeichniss der Dateistruktur
    def root_path
      # Muss von Subklasse implementiert werden
      raise NotImplementedError
    end
    
    # Maximale Grösse des Verzeichnisses
    def max_size
      # Muss von Subklasse implementiert werden
      raise NotImplementedError
    end
    
    def set(key, document)
      path = _path_for_key(key)
      size_change = document.bytesize - File.size(path)
      
      # Es muss solange ausgelagert werden, bis es genug Platz hat.
      while @current_size-oldsize+newsize >= max_size
        swap_item
      end
      
      # Byte Zähler aktualisieren
      @current_size += size_change
      
      file = File.open(path, "w")
      file.write(document)
      file.close
      nil
    end
    
    def get(key)
      path = _path_for_key(key)
      if File.exists? path
        return File.read(path)
      else
        return nil
      end
    end
    
    def delete(key)
      path = _path_for_key(key)
      if File.exists? path
        @current_size -= File.size(path)
        File.unlink(key)
      end
      nil
    end
    
    def swap_item
      raise NotImplementedError
    end
    
    private
    def _path_for_key(key)
      hash = Digest::MD5.hexdigest(key)
      "#{root_path}/#{hash}"
    end
  end
end