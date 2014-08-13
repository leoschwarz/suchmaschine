# Ein Fehler der schmerzhaft lange zu finden gedauert hat, war, dass exec_params(_defer) nicht funktioniert, wenn man versucht eine WHERE $1 = $2 Klausel hinzuzufügen.
# Die Lösung für dieses Problem, die hier angewendet wird, fügt die jeweiligen Feldnamen direkt ein, nicht aber die Werte (SQL-Injektion)
# Das heisst aber, dass die Feldnamen nicht gegen SQL-Injektion sicher sind!
# (Wahrscheinlich wird dies bei dieser Applikation aber sowieso keine Rolle spielen)

module Crawler
  class Database
    def initialize
      @db = PG::EM::ConnectionPool.new(size: Crawler.config.database.connections,
                                       dbname: Crawler.config.database.name,
                                       host: Crawler.config.database.host,
                                       user: Crawler.config.database.user,
                                       password: Crawler.config.database.password)
    end
    
    def self.instance
      @@instance ||= Database.new
    end
    
    def update(table, identifiers, values)
      sql = "UPDATE #{table} SET "
      sql += (0...values.length).to_a.map{|i| "#{values.keys[i]} = $#{i+1}"}.join(",")
      sql += " WHERE "
      sql += (0...identifiers.length).to_a.map{|i| "#{identifiers.keys[i]} = $#{values.length+i+1}"}.join(" AND ")
      @db.exec_params_defer(sql, values.values + identifiers.values)
    end
    
    def insert(table, values)
      sql = "INSERT INTO #{table} ("
      sql += (0...values.length).to_a.map{|i| values.keys[i].to_s}.join(",")
      sql += ") VALUES ("
      sql += (1..values.length).to_a.map{|i| "$#{i}"}.join(",")
      sql += ")"
      @db.exec_params_defer(sql, values.values)
    end
    
    def select(table, identifiers, fields=["*"], limit=nil)
      sql = "SELECT "
      sql += fields.join(",")
      sql += " FROM #{table} WHERE "
      sql += (0...identifiers.length).to_a.map{|i| "#{identifiers.keys[i]} = $#{i+1}"}.join(" AND ")
      unless limit.nil? then sql += " LIMIT #{limit.to_i}" end
      @db.exec_params_defer(sql, identifiers.values)
    end
     
    def query(sql, params=[])
      @db.exec_params_defer(sql, params)
    end
    
    
    
    
    def self.update(table, identifier, values)
      Database.instance.update(table, identifier, values)
    end
    
    def self.insert(table, values)
      Database.instance.insert(table, values)
    end
    
    def self.select(table, identifiers, fields=["*"], limit=nil)
      Database.instance.select(table, identifiers, fields, limit)
    end
    
    def self.query(sql, params=[])
      Database.instance.query(sql, params)
    end
  end
end