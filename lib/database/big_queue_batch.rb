require 'lz4-ruby'

module Database
  class BigQueueBatch
    attr_accessor :path, :size

    def initialize(path)
      @path    = path
      @size    = 0
      @urls    = []

      if File.exists?(@path)
        load
      end
    end

    # Lädt die Datei.
    def load
      raw = LZ4::uncompress(File.read(@path))
      raw.each_line do |line|
        @urls << line.strip
        @size += 1
      end

      @urls.shuffle!
    end

    # Speichert die Datei.
    def save
      File.open(@path, "w") do |file|
        file.write(LZ4::compress(@urls.join("\n")))
      end
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
      @size >= Config.database.batch_size
    end

    def empty?
      @size == 0
    end
  end
end
