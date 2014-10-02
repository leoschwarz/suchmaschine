require 'digest/md5'
require_relative './serializable_struct.rb'

module Crawler
  # FELDER::
  # - url
  # - links
  # - text

  class Document < SerializableStruct
    attr_accessor :hash

    def self.load(hash)
      doc = Document.parse(Database.document_get(hash))
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
