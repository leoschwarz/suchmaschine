module Database
  class RandomQueue
    def initialize(file_path)
      # Die Alte Datei umbenennen
      old_file = "#{file_path}.#{Time.now.to_i}"
      if File.exists? file_path
        `mv "#{file_path}" "#{old_file}"`
      end
      
      # Neue Datei aufsetzen
      @file = File.open(file_path, "w")
      @write_buffer = []
      
      # Alte Werte einlesen
      all_items = []
      File.read(old_file).lines.each do |line|
        cmd, url = line.split(" ", 2)
        if cmd == "INSERT"
          all_items << url
        elsif cmd == "DELETE"
          all_items.delete(url)
        end
      end
      
      @items = []
      all_items.each do |item|
        insert(item)
      end
      all_items = nil
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