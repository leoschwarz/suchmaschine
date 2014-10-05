module Indexer
  class Database
    def self.queue_insert(docinfo_ids)
      self.run("INDEX_QUEUE_INSERT\t#{docinfo_ids.join("\t")}")
    end
    
    def self.queue_fetch()
      self.run("INDEX_QUEUE_FETCH")
    end
    
    def self.run(query)
      client = Common::FastClient.new(Indexer.config.database.host, Indexer.config.database.port)
      client.request(query)
    end
  end
end