############################################################################################
# Ein Dokument bildet das Resultat des Crawl-Vorganges. Das Dokument und die Metadaten     #
# ergänzen einander, wobei letztendlich dem Dokument eher eine Archiv-Funktion zukommt.    #         
############################################################################################

require 'digest/md5'

module Common
  module Database
    class Document
      include Common::Serializable
      
      field :url       # [URL] URL des Dokumentes (URL.stored wird gespeichert)
      field :links, [] # [Array]  Elemente im Format [Anker, URL]
      field :title, "" # [String] Titel des Dokumentes, falls vorhanden
      field :text      # [String] Extrahierter Text aus dem Ursprünglichen Dokument

      def hash
        Digest::MD5.hexdigest(self.url)
      end
      
      def self.fetch(_hash)
        raw = Database.document_get(_hash)
        return nil if raw.nil? or raw.empty?
        document = self.deserialize(raw)
        document.url = Common::URL.stored(document.url)
        document
      end

      def save
        _url = self.url
        self.url = _url.stored
        Database.document_set(self.hash, self.serialize)
        self.url = _url
      end
    end
  end
end
