############################################################################################
# Das SearchCacheItem speichert die Resultate einer Suche, sodass diese nicht jedes Mal    #
# ermittelt werden müssen. Dies wird vor allem dazu gemacht, um die Suche nicht jedes Mal  #
# erneut ausführen zu müssen, wenn der Nutzer eine weitere Seite der Resultate möchte.     #
############################################################################################
require 'digest/md5'

module Frontend
  class SearchCacheItem
    include Common::Serializable

    field :key
    field :query
    field :documents
    field :timestamp

    def valid?
      max_age_seconds = 1800
      Time.now.to_i - max_age_seconds < timestamp
    end

    def self.load(db_backend, query)
      key = Digest::MD5.hexdigest(query)
      raw = db_backend.datastore_get(:search_cache, key)
  
      if raw.nil?
        nil
      else
        deserialize(raw)
      end
    end

    def self.create(db_backend, query, documents)
      item = SearchCacheItem.new
      item.query = query
      item.key   = Digest::MD5.hexdigest(query)
      item.documents = documents
      item.timestamp = Time.now.to_i
      item.save(db_backend)
      item
    end

    def save(db_backend)
      db_backend.datastore_set(:search_cache, key, self.serialize)
    end
  end
end
