module Database
  class BetterQueueBatch
    def initialize(name, metadata)
      @name = name
      @path = File.join(metadata.directory, name)
      @metadata = metadata
      @metadata.batches[name] ||= 0
    end
    
    def rows
      @metadata.batches[@name]
    end
    
    def rows=(_rows)
      @metadata.batches[@name] = _rows
    end
    
    def empty_slots
      Config.database.batch_size - rows
    end
    
    def insert(_rows)
      File.open(@path, "a") do |file|
        file.puts _rows.join("\n")
      end
      rows += _rows.size
    end
    
    def read_all
      File.read(@path).split("\n").shuffle
    end
    
    def delete
      @metadata.batches.delete(@name)
      File.unlink(@path)
    end
    
    # Ein Stapel ist bereits "voll" wenn dieser eigentlich nur zu 75% voll ist.
    # Dabei geht es darum, zu vermeiden, das in viele Stapel jeweils kleine Mengen Zeilen
    # geschrieben werden müssen, und man an Performance einbüssen würde...
    def full?
      empty_slots < 0.75 * Config.database.batch_size
    end
  end
end
