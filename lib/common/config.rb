############################################################################################
# Diese Datei definiert das Modul Config. Entsprechend der Umgebungs-Variable              #
# 'SEARCHENGINE_ENV' wird ein Abschnitt der Konfigurationsdatei ausgewählt und geladen.    #
# Die Konfiguration ist ab dem Zeitpunkt des Ladens über das Modul Config lesbar.          #
############################################################################################
require 'yaml'

# Die veraltete RbConfig Klasse wird noch immer mit Config referenziert.
# Es ist relativ ungefährlich diese Klasse zu entdefinieren, muss aber gemacht werden, da
# ansonsten die Verwendung des Namens "Config" eine Warnung ausgibt.
Object.send(:remove_const, :Config) if defined? Config
module Config
  # Erzeugt ein Objekt welches durch Methoden Zugriffe auf die Elemente für Hash-Schlüssel
  # bietet. Dabei funktioniert dies im Gegensatz zu Ruby's OStruct auch rekursiv.
  # Wenn hash kein Hash ist, wird einfach hash zurückgegeben.
  def self.hash_proxy(hash)
    return hash unless hash.class == Hash

    obj = Object.new
    hash.each_pair do |key, value|
      ret = hash_proxy(value)
      obj.define_singleton_method(key){ ret }
    end
    obj.define_singleton_method(:[]){|key| hash[key.to_s]}
    obj
  end

  # Sicherstellen das eine Umgebung gesetzt ist.
  environment = ENV["SEARCHENGINE_ENV"]
  if environment.nil?
    raise "Die Umgebungsvariable SEARCHENGINE_ENV ist nicht definiert."
  end

  # Konfiguration laden.
  config_path = File.join(File.dirname(__FILE__), "..", "..", "config", "config.yml")
  data = YAML.load(File.read(config_path))[environment]
  if data.nil?
    raise "Konfiguration für SEARCHENGINE_ENV=#{environment} wurde nicht gefunden."
  end
  data.each_pair do |key, value|
    ret = hash_proxy(value)
    self.define_singleton_method(key){ ret }
  end
end
