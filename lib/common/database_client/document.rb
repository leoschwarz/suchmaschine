require 'digest/md5'

module Common
  module DatabaseClient
    class Document < Common::SerializableObject
      field :url        # [String] URL des Dokumentes im Format Common::URL.stored
      field :links, []  # [Array]  Elemente im Format [Anker, URL]
      field :title, ""  # [String] Titel des Dokumentes, falls vorhanden
      field :text       # [String] Extrahierter Text aus dem Ursprünglichen Dokument

      def hash
        Digest::MD5.hexdigest(self.url)
      end

      def self.load(_hash)
        raw = Database.document_get(_hash)
        return nil if raw.nil? or raw.empty?
        self.deserialize(raw)
      end

      def save
        Database.document_set(self.hash, self.serialize)
      end
    end
  end
end
