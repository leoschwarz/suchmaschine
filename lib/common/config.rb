require 'yaml'

Object.send(:remove_const, :Config)

module Config
  # Erzeugt ein Objekt welches durch Methoden Zugriffe auf die Elemente für Hash-Schlüssel bietet
  # Dabei funktioniert dies im Gegensatz zu Ruby's OStruct auch rekursiv.
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
  environment = ENV["LIGHTBLAZE_ENV"]
  if environment.nil?
    puts "Warnung: Die Umgebungsvariable 'LIGHTBLAZE_ENV' ist nicht definiert."
    puts "         Der Standardwert 'wireless' wurde angenommen."
    environment = "wireless"
  end

  # Konfiguration laden.
  data = YAML.load(File.read File.join(File.dirname(__FILE__), "..", "..", "config.yml"))[environment]
  if data.nil?
    raise "Unbekannte Umgebungsvariable: LIGHTBLAZE_ENV=#{environment}"
  end
  data.each_pair do |key, value|
    ret = hash_proxy(value)
    self.define_singleton_method(key){ ret }
  end
end
