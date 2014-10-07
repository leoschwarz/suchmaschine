require 'digest/md5'

module Common
  module DatabaseClient
    class Document < Common::SerializableObject
      field :url        # [String] URL des Dokumentes im Format Common::URL.stored 
      field :links, []  # [Array]  Elemente im Format [Anker, URL]
      field :text       # [String] Extrahierter Text aus dem Ursprünglichen Dokument
      field :html       # [String] HTML des Body Elementes des ursprünglichen HTML
    
      attr_accessor :hash

      def self.load(hash)
        raw = Database.document_get(hash)
        return nil if raw.nil? or raw.empty?
        doc = Document.deserialize(raw)
        doc.hash = hash
        doc
      end

      def save
        serialized = self.serialize
        @hash      = Digest::MD5.hexdigest(serialized)
        Database.document_set(@hash, serialized)
        @hash
      end
    end
  end
end
