module Database
  class RandomQueue
    def initialize(file_path)
      # Die Alte Datei umbenennen
      old_file_path = "#{file_path}.#{Time.now.to_i}"
      if File.exists? file_path
        `mv "#{file_path}" "#{old_file_path}"`
      end
      
      # Neue Datei aufsetzen
      @file = File.open(file_path, "w")
      @write_buffer = []
      
      # Alte Werte einlesen
      @items = []
      old_file = File.open(old_file_path, "r")
      old_file.each_line do |line|
        cmd, url = line.split(" ", 2)
        
        if cmd == "INSERT"
          insert(url)
        elsif cmd == "DELETE"
          # Löschen falls vorhanden
          if @items.include? url
            @items.delete(url)
          else
            # Ansonsten einfach vormerken
            _delete(url)
          end
        end
      end
      old_file.close
    end
    
    def insert(url)
      if @items.size < Database.config.task_queue.max_active
        @items << url
      end
      
      _write("INSERT #{url}")
    end
    
    def fetch
      index = rand(0...@items.size)
      _delete(@items[index])
      @items.slice! index
    end
    
    def size
      @items.size
    end
    
    private
    def _delete(url)
      _write("DELETE #{url}")
    end
    
    def _write(line)
      @write_buffer << line
      if @write_buffer.size >= Database.config.task_queue.storage_buffer
        @file.write(@write_buffer.join(""))
        @file.flush
        @write_buffer.clear
      end
    end
  end
end
