require 'singleton'

module Database
  class StorageDisk
    include Singleton

    def initialize
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

    def set(key, _document)
      # Dokument komprimieren
      document = LZ4::compress(_document)

      # Dokument speichern
      path = _path_for_key(key)

      file = File.open(path, "w")
      file.write(document)
      file.close
      nil
    end

    def get(key)
      path = _path_for_key(key)
      if File.exists? path
        return LZ4::uncompress(File.read(path))
      else
        return nil
      end
    end

    def delete(key)
      path = _path_for_key(key)
      if File.exists? path
        File.unlink(key)
      end
      nil
    end

    def include?(key)
      File.exists?(_path_for_key key)
    end

    private
    def _path_for_key(key)
      "#{root_path}/#{key}"
    end
  end
end
