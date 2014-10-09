require 'digest/md5'

module Common
  module DatabaseClient
    class DocumentInfo < Common::SerializableObject
      field :url                                     # [String]  URL, im Format Common::URL.stored, des Dokumentes
      field :added_at                                # [Integer] Timestamp der Erstellung
      field :permissions, {index: nil, follow: nil}  # [Boolean] index, follow: Meta-Tag Information
      field :document_hash                           # [String]  Hash des aktuellsten Dokumentes
      field :redirect                                # [String]  URL, im Format Common::URL.stored, falls Umleitung

      def document
        Document.load(self.document_hash)
      end

      def document=(doc)
        self.document_hash = doc.hash
      end

      def save
        Database.document_info_set(Digest::MD5.hexdigest(self.url), self.serialize)
      end

      def self.load(hash)
        DocumentInfo.deserialize(Database.document_info_get(hash))
      end
    end
  end
end
