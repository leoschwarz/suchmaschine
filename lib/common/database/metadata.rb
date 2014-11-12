require 'digest/md5'

module Common
  module Database
    class Metadata
      include Common::Serializable
      
      field :url                                     # [URL]     URL des Dokumentes (URL.stored wird gespeichert)
      field :title, ""                               # [String]  Titel des Dokumentes.
      field :added_at                                # [Integer] Timestamp der Erstellung
      field :permissions, {index: nil, follow: nil}  # [Boolean] index, follow: Meta-Tag Information
      field :word_counts, {}                         # [Hash]    Wort => Anzahl, Wie oft kommen die Worte im Dokument vor?
      field :redirect                                # [String]  URL, im Format Common::URL.stored, falls Umleitung
      field :downloaded, true                        # [Boolean] Gibt es ein heruntergeladenes Dokument?

      def hash
        Digest::MD5.hexdigest(self.url)
      end

      def document
        Document.load(self.hash)
      end

      def save
        _url = self.url
        self.url = _url.stored
        Database.metadata_set(self.hash, self.serialize)
        self.url = _url
      end

      def self.load(_hash)
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
