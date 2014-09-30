require 'digest/md5s'

module Crawler
  # FELDER::
  # - url
  # - links
  # - text
  
  class Document < SerializableStruct
    def hash
      Digest::MD5.hexdigest self.text
    end
    
    def self.load(url)
      Document.parse(Database.document_get(url))
    end
    
    def save
      Database.document_set(self.url, serialize)
    end
  end
end