############################################################################################
# Diese Datei lädt sowohl das Common::Database Submodul, als auch den Datenbank-Client.    #
# Die Verwendung erfolgt in der Regel durch ein Mixin des Common::Database Submoduls, den  #
# dann kann man im ganzen Modul auf den Datebank-Client Common::Database::Database zu-     #
# greifen.                                                                                 #
#                                                                                          #
# Die Verbindung zum Datenbankserver wird mithilfe der Distributed Ruby Platform herge-    #
# stellt. Dabei wird auf die Instanz der Klasse ServerFront im Modul Database zugegriffen. #
############################################################################################
require_relative './database.rb'
require_relative './document.rb'
require_relative './metadata.rb'
require 'drb/drb'

module Common
  module Database
    class Database
      def self.download_queue_insert(urls)
        self.run(:download_queue, :insert, urls) unless urls.size == 0
      end

      def self.download_queue_fetch()
        URL.stored(self.run(:download_queue, :fetch))
      end

      def self.index_queue_insert(ids)
        self.run(:index_queue, :insert, ids) unless ids.size == 0
      end

      def self.index_queue_fetch()
        self.run(:index_queue, :fetch)
      end

      def self.cache_set(key, value)
        self.run(:cache, :set, key, value)
      end

      def self.cache_get(key)
        self.run(:cache, :get, key)
      end

      def self.search_cache_set(key, value)
        self.run(:search_cache, :set, key, value)
      end

      def self.search_cache_get(key)
        self.run(:search_cache, :get, key)
      end

      def self.document_set(hash, document)
        self.run(:document, :set, hash, document)
      end

      def self.document_get(hash)
        self.run(:document, :get, hash)
      end

      def self.metadata_set(hash, metadata)
        self.run(:metadata, :set, hash, metadata)
      end

      def self.metadata_get(hash)
        self.run(:metadata, :get, hash)
      end

      def self.run(resource, action, *parameters)
        server = DRbObject.new(nil, Config.database_connection)
        server.execute(resource, action, parameters)
      end
    end
  end
end
