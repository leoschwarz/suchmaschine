module Crawler
  class RobotstxtParser
    include Common::Serializable
    
    field :rules, nil
    field :valid_until
    
    # Erzeugt eine Instanz, wenn möglich werden die Daten aus der Datenbank geladen, ansonsten aus dem Internet.
    # @param domain [String]
    # @return [RobotstxtParser]
    def self.for_domain(domain)
      # Datenbank-Cache überprüfen...
      if (data = Database.cache_get("robotstxt:#{domain}"))
        parser = deserialize(data)
        # Falls noch gültig, ist hier schon fertig.
        return parser if parser.valid_until > Time.now.to_i
      end
      
      # Datei aus dem Internet laden...
      parser = self.new
      parser.fetch(Common::URL.encoded "http://#{@domain}/robots.txt")
      Database.cache_set("robotstxt:#{domain}", parser.serialize)
      parser
    end
    
    # Überprüft ob der Zugriff auf einen Pfad erlaubt ist.
    # @param path [String] Der zu überprüfende Pfad.
    # @return [Boolean]
    def allowed?(path)
      fetch if @rules.nil?
      
      allowed = true
      @rules.each do |rule|
        if /^(#{rule[1]})/.match(path)
          if rule[0] == :disallow
            allowed = false
          elsif rule[0] == :allow
            # Explizit erlaubter Eintrag
            return true
          end
        end
      end
      allowed
    end
    
    private
    # Lädt die robots.txt-Datei herunter und verarbeitet sie.
    # @param url [URL] URL zur Datei.
    # @return [nil]
    def fetch(url)
      download = Crawler::Download.new(url)
      code = download.status[0]
      if code == "2"
        self.rules = parse(download.response_body)
        self.valid_until = Time.now.to_i + Config.robotstxt.lifetime
      elsif code == "3" || code == "5"
        self.rules = [[:disallow, "/"]]
        self.valid_until = Time.now.to_i + 120
      elsif c == "4"
        self.rules = []
        self.valid_until = Time.now.to_i + Config.robotstxt.lifetime
      end
    end
    
    # Verarbeitet die robots.txt-Datei und gibt ein Array an Regeln zurück.
    # @param raw [String] Der Inhalt der robots.txt-Datei.
    # @return [Array]
    def parse(raw)
      # Es wird versucht einen Eintrag extra für diesen "User-Agent" zu finden, und falls keiner
      # gefunden wird, wird einfach der Eintrag für alle verwendet, sofern dieser vorhanden ist.
      default_entries = []
      
      current_agents  = []
      current_entries = []
      opening         = true
      skip            = false
      
      raw.lines.each do |line|
        if (match = /([-a-zA-Z]+):[ ]?(.*)$/.match(line))
          key = match[1].strip.downcase
          value = match[2].strip.downcase
          
          if key == "user-agent"
            if opening
              current_agents << value
            else
              # Die letzte Gruppe ist nun abgeschlossen und kann verwertet werden.
              if current_agents.include?(Config.crawler.agent.downcase)
                return current_entries
              elsif current_agents.include?("*")
                default_entries = current_entries
              end
              
              opening = true
              current_agents = [value]
              current_entries = []
            end
          elsif key == "allow" || key == "disallow"
            if opening
              opening = false
              if current_agents.include? "*" || current_agents.include?(Config.crawler.agent.downcase)
                skip = false
              else
                # Alle Einträge der Gruppe können übersprungen werden, wenn sie sowieso irrelevant sind.
                skip = true
              end
            end
            
            if !skip && !value.empty?
              current_entries << [key.to_sym, convert_to_regex_string(value)]
            end
          end
        end
      end
      
      default_entries
    end
    
    # Kleiner Helfer
    def convert_to_regex_string(value)
      s = Regexp.quote(value)
      s.gsub!(/\\\*/, "(.*)")
      s.gsub!(/\\\$/, "$")
      s
    end
  end
end
