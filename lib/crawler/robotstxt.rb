############################################################################################
# Ein Leser für robots.txt Dateien.                                                        #
# Die Implementierung orientiert sich an der Google Spezifikation, allerdings wurde die    #
# Regex Unterstützung nicht komplett umgesetzt.                                            #
# URL: https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt        #
#                                                                                          #
# Die Klasse Robotstxt stellt ein Interface zur Klasse RobotstxtParser dar, indem versucht #
# wird, einige der übersetzten robots.txt Dokumenten im Arbeitsspeicher zu behalten.       #
############################################################################################
module Crawler
  class Robotstxt
    def initialize
      @parsers = Common::RAMCacheFIFO.new(200)
    end

    def self.instance
      @instance ||= self.new
    end

    # Überprüft ob es erlaubt ist auf die URL zuzugreifen.
    # @param url [URL] Die zu überprüfende URL.
    # @return [Boolean]
    def allowed?(url)
      domain, path = url.domain, url.path
      return false if domain.nil? || path.nil?

      @parsers[domain] ||= RobotstxtParser.for_domain(domain)
      @parsers[domain].allowed?(path)
    end

    def self.allowed?(url)
      self.instance.allowed?(url)
    end
  end
  
  class RobotstxtParser
    include Common::Serializable
    
    field :rules, nil
    field :valid_until
    
    # Erzeugt eine Instanz für eine Domain und versucht die Daten aus dem Cache zu laden.
    # Falls dies nicht erfolgreich ist, wird die robots.txt Datei geladen und gelesen.
    # @param domain [String]
    # @return [RobotstxtParser]
    def self.for_domain(domain)
      # Datenbank-Cache überprüfen.
      if Config.robotstxt.cache.enabled \
      && (data = Crawler::Database.cache_get("robotstxt:#{domain}"))
        parser = deserialize(data)
        # Gültigkeit des Eintrags überprüfen und eventuell Resultat zurückgeben.
        return parser if parser.valid_until > Time.now.to_i
      end
      
      # Datei aus dem Internet laden...
      parser = self.new
      parser.fetch(Common::URL.encoded("http://#{domain}/robots.txt"))
      if Config.robotstxt.cache.enabled
        Crawler::Database.cache_set("robotstxt:#{domain}", parser.serialize)
      end
      parser
    end
    
    # Überprüft ob der Zugriff auf einen Pfad erlaubt ist.
    # @param path [String] Der zu überprüfende Pfad.
    # @return [Boolean]
    def allowed?(path)      
      allowed = true
      self.rules.each do |rule|
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
    
    # Lädt die robots.txt-Datei herunter und verarbeitet sie.
    # @param url [URL] URL zur Datei.
    # @return [nil]
    def fetch(url)
      download = Crawler::Download.new(url)
      code = download.status[0]
      if code == "2"
        self.rules = parse(download.response_body)
        self.valid_until = Time.now.to_i + Config.robotstxt.cache.lifetime
      elsif code == "3" || code == "5"
        self.rules = [[:disallow, "/"]]
        self.valid_until = Time.now.to_i + 120
      elsif code == "4"
        self.rules = []
        self.valid_until = Time.now.to_i + Config.robotstxt.cache.lifetime
      end
    end
    
    private
    # Verarbeitet die robots.txt-Datei und gibt ein Array an Regeln zurück.
    # @param raw [String] Der Inhalt der robots.txt-Datei.
    # @return [Array]
    def parse(raw)
      # Es wird versucht einen Eintrag extra für diesen "User-Agent" zu finden,
      # und falls keiner gefunden wurde, wird einfach der Eintrag für alle verwendet,
      # sofern dieser vorhanden ist.
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
              if current_agents.include? "*" \
              || current_agents.include?(Config.crawler.agent.downcase)
                skip = false
              else
                # Alle Einträge der Gruppe können übersprungen werden,
                # wenn die Gruppe sowieso irrelevant für uns ist.
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
