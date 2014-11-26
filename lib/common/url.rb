require 'uri'

module Common
  # Diese Klasse abstrahiert (und vereinfacht) die Handhabung von URLs.
  # Generell werden hier drei verschiedene Formen von URLs unterschieden:
  # - encoded: Kodierte URLs in denen keine Sonderzeichen vorkommen, sie beginnen mit dem Schema.
  # - decoded: Dekodierte URLs in denen Sonderzeichen vorkommen, sie beginnen mit dem Schema.
  # - stored: Kodierte URLs in denen keine Sonderzeichen vorkommen, sie beginnen ohne das Schema.
  class URL
    # Handelt es sich um eine absolute URL?
    attr_reader :full_url

    # Die Klassenmethode 'new' privat machen.
    # Es soll immer einer der Konstruktoren encoded, decoded oder stored explizit verwendet werden.
    private_class_method :new
    
    # Erzeugt eine neue URL Instanz.
    # @param encoded_url [String] Die kodierte URL mit dem Schema.
    # @param full_url [Boolean] Handelt es sich um eine absolute URL?
    def initialize(encoded_url, full_url=true)
      @encoded_url = encoded_url
      @full_url    = full_url
    end

    # URL mit kodierten Sonderzeichen
    # Beispiel: http://de.wikipedia.org/wiki/K%C3%A4se
    # @return [String]
    def encoded_url
      @encoded_url
    end

    # URL mit dekodierten Sonderzeichen, also ein UTF-8 String
    # Beispiel: http://de.wikipedia.org/wiki/Käse
    # @return [String]
    def decoded_url
      @_decoded_url ||= URI.decode @encoded_url
    end

    # URL die in der Datenbank gespeichert wird. Ohne URI-Schema, mit kodierten Sonderzeichen
    # Beispiel: de.wikipedia.org/wiki/K%C3%A4se
    # @return [String]
    def stored_url
      @_stored_url ||= @encoded_url.gsub(%r{^https?://}, "")
    end

    # Aliase
    alias :encoded :encoded_url
    alias :decoded :decoded_url
    alias :stored :stored_url
    
    # Entfernt den Fragmentbezeichner von der URL.
    # @return [nil]
    def remove_fragment_identifier
      @_decoded_url = nil
      @_stored_url  = nil
      @encoded_url  = @encoded_url.split("#")[0]
    end

    # Gibt den kodierten Domainnamen der URL zurück.
    # @return [String, nil] Domain Name in Kleinbuchstaben
    def domain
      @url_parts ||= url_parts
      return nil if @url_parts[0].nil?
      @url_parts[0].downcase
    end
    
    # Gibt den Pfad der URL zurück.
    # @return [String, nil] Pfad beginnend mit "/"
    def path
      @url_parts ||= url_parts
      return nil if @url_parts[1].nil?
      return "/" if @url_parts[1].empty?
      @url_parts[1]
    end

    # Neue URL-Instanz aus URL im "encoded" Format erstellen.
    # @param url [String] Die kodierte URL mit Schema.
    # @return [URL]
    def self.encoded(url)
      new(url)
    end

    # Neue URL-Instanz aus URL im "decoded" Format erstellen.
    # @param url [String] Die dekodierte URL mit Schema.
    # @return [URL]
    def self.decoded(url)
      new(URI.encode url)
    end

    # Neue URL-Instanz aus URL im "stored" Format erstellen.
    # @param url [String] Die kodierte URL ohne Schema.
    # @return [URL]
    def self.stored(url)
      new("http://"+url)
    end

    # Wandelt die URL-Instanz in eine URI-Instanz um.
    # @return [URI]
    def to_uri
      URI(encoded_url)
    end
    
    # Interpretiert die als Parameter gegebene URL als Link der auf einer Webseite gefunden
    # wurde und evaluiert die Ziel-URL. Falls es sich um eine relative handelt, wird sie
    # an das Ende hinzugefügt, falls es sich um eine absolute handelt, wird die absolute zurückgegeben
    # und falls es sich um etwas handelt das keine URL ist oder es andere Fehler gibt, wird nil zurückgegeben.
    # @param [URL, String]
    # @return [URL, nil]    
    def join_with(url)
      # Eventuelle Typkonvertierung des Parameters
      url = URL.from_unknown(url) if url.class == String
      
      # Wir sind fertig, falls die URL nil ist oder es sich um eine absolute URL handelt.
      return nil if url.nil?
      return url if url.full_url
      
      # Die URIs zusammenfügen
      begin
        url = URI::join(self.to_uri, url.to_uri).to_s
        URL.encoded(url)
      rescue
        nil
      end
    end

    # Versucht einen String, dessen Typ ungeklärt ist, in ein URL Objekt zu konvertieren.
    # Es werden nur encoded und decoded unterstützt.
    # Falls dies nicht gelingt wird stattdessen nil zurückgegeben.
    # @param string [String] Der zu konvertierende String.
    # @param second_try [Boolean] Soll ein zweiter Versuch erlaubt sein? (In dem Fall wird versucht die URL zu kodieren)
    # @return [URL, nil]
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
      return self.from_unknown(URI.encode(string).to_s, false) if second_try
      nil
    end
    
    private
    # Teilt die kodierte URL in die Domain und den Pfad auf.
    # @return [Array]
    def url_parts
      match = %r{^http[s]?://([a-zA-Z0-9\.-]+)(.*)}.match(@encoded_url)
      result = []
      if match
        [match[1], match[2]]
      else
        [nil, nil]
      end
    end
  end
end
