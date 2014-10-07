require 'digest/md5'

module Crawler
  # FELDER::
  # - url
  # - links
  # - text

  class Document < Common::SerializableObject
    field :url
    field :links, []
    field :text
    
    attr_accessor :hash

    def self.load(hash)
      raw = Database.document_get(hash)
      return nil if raw.nil? or raw.empty?
      doc = Document.parse(raw[0])
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
