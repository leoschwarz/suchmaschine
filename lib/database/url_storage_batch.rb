module Database
  class URLStorageBatch
    attr_accessor :path, :size
    
    def intialize(path)
      @path    = path
      @size    = 0
      @urls    = []
      
      if File.exists?(@path)
        load
      end
    end
    
    # Lädt die Datei.
    def load
      file = File.open(@path, "r")
      file.each_line do |line|
        @urls << line.strip
        @size += 1
      end
      file.close
      
      @urls.shuffle!
    end
    
    # Speichert die Datei.
    def save
      file = File.open(@path, "w")
      file.write(@urls.join("\n"))
      file.close
    end
    
    # Löscht die Datei.
    def delete
      File.unlink @path
    end
    
    # Fügt eine URL hinzu.
    def insert(url)
      @urls << url
      @size += 1
    end
    
    # Nimmt eine URL aus der Liste.
    def fetch
      if @size > 0
        @size -= 1
        @urls.pop
      else
        nil
      end
    end
    
    def full?
      @size >= Database.config.url_storage.batch_size
    end
    
    def empty?
      @size == 0
    end
  end
end