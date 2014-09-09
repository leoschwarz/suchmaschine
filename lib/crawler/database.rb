# Ein Fehler der schmerzhaft lange zu finden gedauert hat, war, dass exec_params(_defer) nicht funktioniert, wenn man versucht eine WHERE $1 = $2 Klausel hinzuzufügen.
# Die Lösung für dieses Problem, die hier angewendet wird, fügt die jeweiligen Feldnamen direkt ein, nicht aber die Werte (SQL-Injektion)
# Das heisst aber, dass die Feldnamen nicht gegen SQL-Injektion sicher sind!
# (Wahrscheinlich wird dies bei dieser Applikation aber sowieso keine Rolle spielen)

module Crawler
  class Database    
    def initialize
      @redis = Redis.new(url: Crawler.config.redis)
    end
    
    def self.instance
      @@instance ||= Database.new
    end
    
    def redis
      @redis
    end
    
    
    # Sorgt dafür dass die Singelton Instanz Methoden auch als Klassenmethoden aufgerufen werden können.
    def self.method_missing(method, *args, &block)
      if Database.instance.respond_to?(method)
        Database.instance.send(method, *args, &block)
      else
        super
      end
    end
  end
end