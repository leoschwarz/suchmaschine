############################################################################################
# Der HTMLParser arbeitet HTML-Dokumente für die weitere Verwendung auf.                   #
# Dabei werden folgenden Informationen extrahiert:                                         #
# - Titel des Dokumentes                                                                   #
# - Erlaubnis das Dokument zu indexieren und Links zu verfolgen                            #
# - Fliesstext des Dokumentkörpers, falls die Indexierung erlaubt ist                      #
# - Links die verfolgt werden dürfen                                                       #
############################################################################################

#require 'nokogiri'

require 'oga'

module Crawler
  class HTMLParser
    attr_reader :links, :text, :title

    # Initialisiert eine neue Parser-Instanz und verarbeitet das Dokument.
    # @param base_url [URL] Die URL des Dokumentes (wird für relative Links benötigt).
    # @param html [String] Das HTML das gelesen werden soll.
    def initialize(base_url, html)
      # Instanzvariabeln setzen
      @base_url = base_url
      @doc      = Oga.parse_html(html)
      @links    = []
      @text     = ""

      # HTML-Verarbeitung
      @title = extract_title
      @permissions = extract_permissions if title_ok?
      @links = extract_links if permissions[:follow]
      if permissions[:index]
        remove_invisible_items
        @text = extract_text
      end
    end

    # Gibt die Berechtigungen der Suchmaschine zurück.
    # @return [Hash]
    def permissions
      @permissions || {index: true, follow: true}
    end

    # Überprüft ob der Dokumenttitel in Ordnung ist.
    # @return [Boolean]
    def title_ok?
      @title != nil
    end

    private
    # Entfernt alle mehrfachen Wiederholungen von Leerzeichen,
    # sowie leerzeichen zu Beginn und Ende des Strings.
    # @param text [String]
    # @return [String]
    def clean_text(text)
      text.gsub(/\s+/, " ").strip
    end

    # Entfernt Scripts, Styles und Kommentare aus dem Dokument.
    # @return [nil]
    def remove_invisible_items
      @doc.search("script").each{|el| el.unlink}
      @doc.search("style").each{|el| el.unlink}
      @doc.xpath("//comment()").remove
    end

    # Extrahiert den Titel aus dem Dokument.
    # @return [String,nil] Auf 100 Zeichen gekürzter Titel bzw. nil falls kein Titel
    def extract_title
      title_tag = @doc.xpath("//title")[0]
      return nil if title_tag.nil?
      return nil if (title = clean_text(title_tag.text)).size < 1
      title[0..100]
    end

    # Extrahiert die Bot-Berechtigungen aus dem Dokument.
    # Standardwerte werden angenommen, wenn keine Informationen im Dokument gefunden werden.
    # @return [Hash]
    def extract_permissions
      result = {index: true, follow: true}
      if (metatag_robots = @doc.at_xpath("//meta[@name='robots']/@content")) != nil
        data = metatag_robots.text.downcase
        result[:index]  = !data.include?("noindex")
        result[:follow] = !data.include?("nofollow")
      end
      result
    end

    # Extrahiert die Links aus dem Dokument.
    # Nur gültige Links werden zurückgegeben.
    # @return [Array]
    def extract_links
      links = []
      @doc.xpath('//a[@href]').each do |link|
        if link['rel'].nil? or not link['rel'].include?("nofollow")
          url = @base_url.join_with(link['href'])
          links << [clean_text(link.text), url] unless url.nil?
        end
      end
      links
    end

    # Extrahiert den Fliesstext aus dem Dokumentkörper.
    # @return [String]
    def extract_text
      clean_text(@doc.text)
    end
  end
end
