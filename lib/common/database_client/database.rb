module Common
  module DatabaseClient
    class Database
      def self.download_queue_insert(urls)
        self.run("DOWNLOAD_QUEUE_INSERT\t#{urls.join("\t")}") unless urls.size == 0
      end

      def self.download_queue_fetch()
        URL.stored(self.run("DOWNLOAD_QUEUE_FETCH", {response_required: true}))
      end

      def self.index_queue_insert(docinfo_ids)
        self.run("INDEX_QUEUE_INSERT\t#{docinfo_ids.join("\t")}") unless docinfo_ids.size == 0
      end

      def self.index_queue_fetch()
        self.run("INDEX_QUEUE_FETCH")
      end

      def self.index_append(pairs)
        self.run("INDEX_APPEND\t#{pairs.flatten.join("\t")}")
      end

      def self.index_get(word)
        raw = self.run("INDEX_GET\t#{word}")
        if raw.nil?
          []
        else
          raw.split("\t")
        end
      end

      def self.cache_set(key, value)
        self.run("CACHE_SET\t#{key}\t#{value}")
      end

      def self.cache_get(key)
        self.run("CACHE_GET\t#{key}")
      end

      def self.document_set(hash, document)
        self.run("DOCUMENT_SET\t#{hash}\t#{document}")
      end

      def self.document_get(hash)
        self.run("DOCUMENT_GET\t#{hash}")
      end

      def self.metadata_set(hash, docinfo)
        self.run("METADATA_SET\t#{hash}\t#{docinfo}")
      end

      def self.metadata_get(hash)
        self.run("METADATA_GET\t#{hash}")
      end

      # Führt ein 'query' auf dem Datenbankserver aus.
      # Optionen:
      # response_required: [Boolean] Muss eine Antwort erhalten werden?
      #                              Falls keine zurück gegeben wird, wird erneut versucht eine Antwort zu erhalten.
      # retries_left: [Integer]      Wieviele Wiederholversuche verbleiben
      def self.run(query, options={})
        options[:response_required] = false if options[:response_required].nil?
        options[:retries_left]      = 3     if options[:retries_left].nil?

        client   = Common::FastClient.new(Config.database.host, Config.database.port)
        response = client.request(query)
        if options[:response_required]
          if response.nil? or response.empty?
            # Darf noch ein Request gesendet werden?
            if options[:retries_left] > 0
              options[:retries_left] -= 1
              # 1s warten bis erneut versucht wird:
              sleep 1
              return self.run(query, options)
            else
              raise RuntimeError.new("Fehler bei der Ausführung einer Datenbankabfrage.")
            end
          end
        end

        response
      end
    end
  end
end
