require_relative './database.rb'
require_relative './document.rb'
require_relative './metadata.rb'
require_relative './postings.rb'
require_relative './postings_block.rb'
require_relative './postings_metadata.rb'

require 'drb/drb'

module Common
  module Database
    class Database
      def self.download_queue_insert(urls)
        self.run(:download_queue_insert, urls) unless urls.size == 0
      end

      def self.download_queue_fetch()
        URL.stored(self.run(:download_queue_fetch))
      end

      def self.index_queue_insert(doc_ids)
        self.run(:index_queue_insert, doc_ids) unless doc_ids.size == 0
      end

      def self.index_queue_fetch()
        self.run(:index_queue_fetch)
      end
      
      def self.index_get(word)
        r = self.run(:index_get, word)
        return [] if r.nil?
        r.split("\t")
      end

      def self.cache_set(key, value)
        self.run(:cache_set, key, value)
      end

      def self.cache_get(key)
        self.run(:cache_get, key)
      end

      def self.document_set(hash, document)
        self.run(:document_set, hash, document)
      end

      def self.document_get(hash)
        self.run(:document_get, hash)
      end

      def self.metadata_set(hash, metadata)
        self.run(:metadata_set, hash, metadata)
      end

      def self.metadata_get(hash)
        self.run(:metadata_get, hash)
      end
      
      def self.postings_block_get(id, temporary=false)
        self.run(:postings_block_get, id, temporary)
      end
      
      def self.postings_block_set(id, data, temporary=false)
        self.run(:postings_block_set, id, data, temporary)
      end
      
      def self.postings_block_delete(id, temporary=false)
        self.run(:postings_block_delete, id, temporary)
      end
      
      def self.postings_metadata_get(word, temporary=false)
        self.run(:postings_metadata_get, word, temporary)
      end
      
      def self.postings_metadata_set(word, data, temporary=false)
        self.run(:postings_metadata_set, word, data, temporary)
      end
      
      def self.run(command, *params)
        server = DRbObject.new(nil, Config.database_connection)
        server.execute(command, params)
      end
    end
  end
end
