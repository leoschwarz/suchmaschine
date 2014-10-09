module Database
  class Index
    # Fügt docinfo_id zu einem existierendem Index File hinzu oder erstellt ein neues.
    def append(word, doc_id)
      file_path = File.join(Database.config.index.directory, "word:#{word}")
      File.open(file_path, "a") do |file|
        file.puts doc_id
      end
    end
  end
end
