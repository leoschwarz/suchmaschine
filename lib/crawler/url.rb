require 'uri'

module Crawler
  
  # @stored_url -> URL die in der Datenbank gespeichert wird. Ohne HTTP/HTTPs Schema, aber mit dekodierten Sonderzeichen
  # @encoded_url -> URL mit kodierten Sonderzeichen (Beispiel: http://de.wikipedia.org/wiki/K%C3%A4se)
  # @decoded_url -> URL mit dekodierten Sonderzeichen, also ein UTF-8 string (Beispiel: http://de.wikipedia.org/wiki/Käse)
  
  
  class URL
    private_class_method :new
    def initialize(encoded_url)
      @encoded_url = encoded_url
    end
    
    alias :encoded, :encoded_url
    alias :decoded, :decoded_url
    alias :stored, :stored_url
    
    def encoded_url
      @encoded_url
    end
    
    def decoded_url
      @_decoded_url ||= URI.decode @encoded_url
    end
    
    def stored_url
      @_stored_url ||= URI.decode(@encoded_url.gsub(%r{^https?://}, ""))
    end
    
    def domain_name
      Domain.domain_name_of(@encoded_url)
    end
    
    def self.encoded(url)
      new(url)
    end
    
    def self.decoded(url)
      new(URI.encode url)
    end
    
    def self.stored(url)
      new("http://"+URI.encode(url))
    end
  end
end
