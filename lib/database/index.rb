module Database
  class Index
    # Fügt docinfo_id zu einem existierendem Index File hinzu oder erstellt ein neues.
    def self.append(word, doc_id)
      File.open(index_path(word), "a") do |file|
        file.puts doc_id
      end
    end

    # Liest eine Datei
    def self.get(word)
      path = index_path(word)
      return nil unless File.exist? path
      return File.read(path)
    end

    private
    def self.index_path(word)
      File.join(Config.paths.index + "word:#{word}")
    end
  end
end
