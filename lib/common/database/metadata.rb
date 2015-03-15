############################################################################################
# Die Metadaten eines Dokumentes enthalten wie der Name schon sagt Metadaten über          #
# Dokumente. Die Metadaten enthalten eine Liste der Anzahl Auftreten jedes Wortes, aber    #
# im Gegensatz zu den Dokumenten nicht den gesammten Fliesstext des Dokumentkörpers.       #
# Die Metadaten werden von der Datenbank auf der SSD gespeichert, um so schnelle Zugriffs- #
# zeiten zu erreichen.                                                                     #
############################################################################################
require 'digest/md5'

module Common
  module Database
    class Metadata
      include Common::Serializable

      # [URL/String] Es wird URL.stored gespeichert, aber wenn die Metadaten mit fetch
      # geladen wurden, wird stattdessen auf ein [URL] Objekt verwiesen.
      field :url
      # [String] Der Dokumenttitel
      field :title, ""
      # [Integer] Timestamp der Erstellung
      field :added_at
      # [Symbol=>Boolean] Erlaubnis das Dokument zu indexieren und zu verfolgen.
      field :permissions, {index: nil, follow: nil}
      # [String=>Integer] Anzahl Auftreten eines jeden Wortes.
      field :word_counts, {}
      # [String] URL im Format Common::URL.stored, falls es eine Umleitung gibt.
      field :redirect
      # [Boolean] Gibt es ein heruntergeladenes Dokument?
      field :downloaded, true

      def word_counts_total
        self.word_counts.values.inject(:+).to_i
      end

      def hash
        if self.url.class == URL
          Digest::MD5.hexdigest(self.url.stored)
        elsif self.url.class == String
          Digest::MD5.hexdigest(self.url)
        else
          raise "Falscher Typ für url: #{self.url.class}"
        end
      end

      def document
        Document.fetch(self.hash)
      end

      def save
        _url = self.url
        self.url = _url.stored
        Database.metadata_set(self.hash, self.serialize)
        self.url = _url
      end

      def self.fetch(_hash)
        raw = Database.metadata_get(_hash)
        if raw.nil?
          return nil
        end

        metadata = self.deserialize(raw)
        metadata.url = Common::URL.stored(metadata.url)
        metadata
      end
    end
  end
end
