require 'oj'

module Crawler
  # Felder:
  # [string] encoded_url    Ursprungs URL
  # [int]    timestamp      Abrufzeit
  # [bool]   index_allowed  Ist es erlaubt den Text in den Index zu speichern (wenn false -> kein Text -> kein Dokument)
  # [bool]   follow_allowed Ist es erlaubt die Links zu verfolgen (wenn false -> links = [])
  # [array]  links          Zwei dimensionales Array, links[n] = link, link[0] = Ankertext, link[1] = Absolute URL
  # [string] text           Extrahierter Text der Webseite
  
  class Document
    attr_accessor :encoded_url, :timestamp, :index_allowed, :follow_allowed, :links, :text
    
    def initialize(encoded_url:nil, timestamp:nil, index_allowed:nil, follow_allowed:nil, links:nil, text:nil)
      @encoded_url    = encoded_url
      @timestamp      = timestamp
      @index_allowed  = index_allowed
      @follow_allowed = follow_allowed
      @links          = links
      @text           = text
    end
    
    def serialize
      Oj.dump({encoded_url: @encoded_url, timestamp: @timestamp, index_allowed: @index_allowed, follow_allowed: @follow_allowed, links: @links, text: @text}, {mode: :object})
    end
    
    def save
      Database.document_set(@encoded_url, serialize)
    end
    
    def self.parse(json)
      data = Oj.load(json, {mode: :object})
      Document.new(encoded_url: data[:encoded_url], timestamp: data[:timestamp], index_allowed: data[:index_allowed], follow_allowed: data[:follow_allowed], links: data[:links], text: data[:text])
    end
    
    def self.get(encoded_url)
      raw_data = Database.document_get(encoded_url)
      if not raw_data.nil?
        self.parse(raw_data)
      else
        nil
      end
    end
  end
end