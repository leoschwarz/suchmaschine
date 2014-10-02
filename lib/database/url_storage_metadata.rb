require 'oj'

module Database
  class URLStorageMetadata
    def initialize(path, data=nil)
      @path = path
      @data = data
      
      if @data.nil?
        @data = {full_batches: [], open_batch: nil, batch_counter: 0}
      end
    end
    
    def full_batches
      @data[:full_batches]
    end
    def open_batch
      @data[:open_batch]
    end
    def open_batch=(val)
      @data[:open_batch] = val
    end
    def batch_counter
      @data[:batch_counter]
    end
    def batch_counter=(val)
      @data[:batch_counter] = val
    end
    
    def next_batchname
      batch_counter += 1
      batch_counter.to_s(16)
    end
    
    def serialize
      Oj.dump(@data)
    end
    
    def save
      File.open(@path, "w") do |file|
        file.write(self.serialize)
      end
    end
    
    def self.load(path)
      json = File.read(path)
      self.new(path, Oj.load(json))
    end
    
    # Öffnet die metadata.json Datei in einem bestimmten Verzeichniss.
    # Bei Erfolg wird eine URLStorageMetadata Instanz zurückgegeben,
    # ansonsten wird nil zurückgegeben.
    def self.open_directory(dir)
      path = File.join(dir, "metadata.json")
      if File.exists? path
        self.load(path)
      else
        nil
      end
    end
  end
end