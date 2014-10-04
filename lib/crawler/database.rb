module Crawler
  class Database
    def self.queue_insert(urls)
      self.run("QUEUE_INSERT\t#{urls.join("\t")}")
    end
    
    def self.queue_fetch()
      stored_url = self.run("QUEUE_FETCH", {response_required: true})
      Task.new(URL.stored stored_url)
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
    
    def self.document_info_set(url, docinfo)
      self.run("DOCUMENT_INFO_SET\t#{url}\t#{docinfo}")
    end
    
    def self.document_info_get(url)
      self.run("DOCUMENT_INFO_GET\t#{url}")
    end
    
    # Führt ein 'query' auf dem Datenbankserver aus.
    # Optionen:
    # response_required: [Boolean] Muss eine Antwort erhalten werden?
    #                              Falls keine zurück gegeben wird, wird erneut versucht eine Antwort zu erhalten.
    # retries_left: [Integer]      Wieviele Wiederholversuche verbleiben
    def self.run(query, options={})
      options[:response_required] = false if options[:response_required].nil?
      options[:retries_left]      = 3     if options[:retries_left].nil?
      
      client   = Common::FastClient.new(Crawler.config.database.host, Crawler.config.database.port)
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