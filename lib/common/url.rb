require 'uri'

module Common
  class URL
    attr_reader :full_url

    private_class_method :new
    def initialize(encoded_url, full_url=true)
      @encoded_url = encoded_url
      @full_url    = full_url
    end

    # URL mit kodierten Sonderzeichen
    # Beispiel: http://de.wikipedia.org/wiki/K%C3%A4se
    def encoded_url
      @encoded_url
    end

    # URL mit dekodierten Sonderzeichen, also ein UTF-8 String
    # Beispiel: http://de.wikipedia.org/wiki/Käse
    def decoded_url
      @_decoded_url ||= URI.decode @encoded_url
    end

    # URL die in der Datenbank gespeichert wird. Ohne URI-Schema, mit kodierten Sonderzeichen
    # Beispiel: de.wikipedia.org/wiki/K%C3%A4se
    def stored_url
      @_stored_url ||= @encoded_url.gsub(%r{^https?://}, "")
    end

    alias :encoded :encoded_url
    alias :decoded :decoded_url
    alias :stored :stored_url

    def domain_name
      match = /https?:\/\/([a-zA-Z0-9\.-]+)/.match(self.encoded_url)
      if not match.nil?
        domain_name = match[1].downcase
      else
        nil
      end
    end

    def self.encoded(url)
      new(url)
    end

    def self.decoded(url)
      new(URI.encode url)
    end

    def self.stored(url)
      new("http://"+url)
    end

    def to_uri
      URI(encoded_url)
    end

    # Evaluiert wohin die als Parameter gegebene URL führt,
    # wenn man sich gerade bei der URL der Instanz befindet.
    # Gibt eine neue URL Instanz oder nil zurück.
    def join_with(url)
      if url.class == String
        url = URL.from_unknown(url)
      end
      if url.nil? or url.full_url
        return url
      end

      # Die URIs zusammenfügen
      begin
        url = URI::join(self.to_uri, url.to_uri).to_s
        # Den Fragmentidentifier von der URL entfernen (falls vorhanden)
        hash_index = url.index("#")
        if hash_index.nil?
          URL.encoded url
        else
          URL.encoded url[0...hash_index]
        end
      rescue
        nil
      end
    end

    # Versucht aus einem String, dessen Typ ungeklärt ist, ein URL Objekt zu machen.
    # Falls dies nicht gelingt wird stattdessen nil zurückgegeben.
    def self.from_unknown(string, second_try=true)
      # 1. Versuch: die URL enthält keine besonderen Sonderzeichen...
      begin
        uri = URI.parse(string)
        if uri.scheme == "http" || uri.scheme == "https"
          # Absolute URL
          return new(uri.to_s, true)
        elsif uri.scheme == nil
          # Relative URL
          return new(uri.to_s, false)
        else
          # Falsches Schema
          return nil
        end
      rescue
      end

      # 2. Versuch: die URL enthält kodierbare Sonderzeichen...
      if second_try
        begin
          return self.from_unknown(URI.encode(string).to_s, false)
        rescue
          return nil
        end
      end

      nil
    end
  end
end
