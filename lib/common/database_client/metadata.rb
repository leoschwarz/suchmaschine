require 'digest/md5'

module Common
  module DatabaseClient
    class Metadata < Common::SerializableObject
      field :url                                     # [String]  URL, im Format Common::URL.stored, des Dokumentes
      field :title, ""                               # [String]  Titel des Dokumentes.
      field :added_at                                # [Integer] Timestamp der Erstellung
      field :permissions, {index: nil, follow: nil}  # [Boolean] index, follow: Meta-Tag Information
      field :redirect                                # [String]  URL, im Format Common::URL.stored, falls Umleitung
      field :downloaded, true                        # [Boolean] Gibt es ein heruntergeladenes Dokument?

      def hash
        Digest::MD5.hexdigest(self.url)
      end

      def document
        Document.load(self.hash)
      end

      def save
        Database.metadata_set(self.hash, self.serialize)
      end

      def self.load(_hash)
        self.deserialize(Database.metadata_get(_hash))
      end
    end
  end
end
