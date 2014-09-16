require 'oj'

module Crawler
  # Felder:
  # [string] encoded_url    Ursprungs URL
  # [int]    timestamp      Abrufzeit
  # [bool]   index_allowed  Ist es erlaubt den Text in den Index zu speichern (wenn false -> kein Text -> kein Dokument)
  # [bool]   follow_allowed Ist es erlaubt die Links zu verfolgen (wenn false -> links = [])
  # [array]  links          zwei dimensionales Array, links[n] = link, link[0] = Ankertext, link[1] = Absolute URL
  # [string] document_hash  Hash des gespeicherten Dokumentes (Name des Dokumentes)
  
  class DocumentData
    
    
    attr_accessor :encoded_url, :timestamp, :index_allowed, :follow_allowed, :links, :document_hash
    
    def initialize(encoded_url, timestamp, index_allowed, follow_allowed, links, document_hash)
      @encoded_url    = encoded_url
      @timestamp      = timestamp
      @index_allowed  = index_allowed
      @follow_allowed = follow_allowed
      @links          = links
      @document_hash  = document_hash
    end
    
    def serialize
      Oj.dump({encoded_url: @encoded_url, timestamp: @timestamp, index_allowed: @index_allowed, follow_allowed: @follow_allowed, links: @links, document_hash: @document_hash}, {mode: :object})
    end
    
    def save
      TaskQueue.set_docdata([@encoded_url, serialize])
    end
    
    def self.parse(json)
      data = Oj.load(json, {mode: :object})
      DocumentData.new(data[:encoded_url], data[:timestamp], data[:index_allowed], data[:follow_allowed], data[:links], data[:document_hash])
    end
    
    def self.get(encoded_url)
      raw_data = TaskQueue.get_docdata([encoded_url])
      if not raw_data.nil?
        self.parse(raw_data)
      else
        nil
      end
    end
  end
end