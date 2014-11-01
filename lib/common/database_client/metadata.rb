require 'digest/md5'

module Common
  module DatabaseClient
    class Metadata
      include Common::Serializable
      
      field :url                                     # [URL]  URL des Dokumentes (URL.stored wird gespeichert)
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
        metadata = self.deserialize(Database.metadata_get(_hash))
        metadata.url = Common::URL.stored(metadata.url)
        metadata
      end
      
      # TODO: Dies wird z.z. nur von Frontend::SearchRunner benötigt und ist keine wirklich schöne Lösung
      #       und sollte deshalb wenn möglich entfernt werden...
      def self.open(path_or_hash, full_path)
        if full_path
          path = path_or_hash
        else
          path = Config.paths.metadata + path_or_hash
        end
        
        metadata = self.deserialize(LZ4.uncompress File.read(path))
        metadata.url = Common::URL.stored(metadata.url)
        metadata
      end
    end
  end
end
