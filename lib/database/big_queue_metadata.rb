require 'oj'

module Database
  class BigQueueMetadata
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
      self.batch_counter += 1
      self.batch_counter.to_s(16)
    end

    def serialize
      Oj.dump(@data)
    end

    def save
      File.open(@path, "w") do |file|
        file.write(self.serialize)
      end
    end

    # Erzeugt eine Instanz für eine Datei.
    # Falls die Datei nicht existiert wird eine neue, leere erzeugt.
    def self.load(path)
      if File.exists?(path)
        self.new(path, Oj.load(File.read(path)))
      else
        self.new(path)
      end
    end
  end
end
