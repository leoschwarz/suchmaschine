require_relative './serializable_struct.rb'

module Crawler
  # FELDER::
  # - url [String]
  # - added_at [Integer]
  # - permissions: [Hash]
  # + permissions.index [Boolean]
  # + permissions.follow [Boolean]
  # - document_hash [String]
  # - redirect [String] (nur definiert wenn vorhanden)

  class DocumentInfo < SerializableStruct
    def document
      Document.load(self.document_hash)
    end

    def document=(doc)
      self.document_hash = doc.hash
    end

    def save
      Database.document_info_set(self.url, serialize)
    end

    def self.load(url)
      DocumentInfo.parse(Database.document_info_get(url))
    end
  end
end
