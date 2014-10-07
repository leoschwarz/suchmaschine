require 'yaml'

module Common
  # Konfiguration aus Konfigurationsdatei in ein Modul laden.
  # Dazu wird die Modulvariable @@config und die Funktion config definiert.
  def self.load_configuration(module_ref, file_name)
    unless module_ref.method_defined? :config
      file_path = File.join(File.dirname(__FILE__), "..", "..", "config", file_name)
      data      = YAML.load(File.read(file_path))
    
      environment = ENV["LIGHTBLAZE_ENV"]
      if environment.nil?
        puts "Warnung: Die Umgebungsvariable 'LIGHTBLAZE_ENV' ist nicht definiert."
        puts "         Der Standardwert 'development' wurde angenommen."
        environment = "development"
      end
    
      module_ref.class_variable_set(:@@config, NeatHash.load(data[environment]))
      module_ref.send :define_singleton_method, :config do
        self.class_variable_get(:@@config)
      end
    end
  end
  
  class NeatHash
    # TODO: Wahrscheinlich ist dies unschön genug, dass es sich doch lohnen würde
    #       evtl. den 'config'-Hash direkt zu verwenden.
    def self.load(hash)
      klass = Class.new
      hash.each_pair do |key, value|
        if value.class == Hash
          value = self.load(value)
        end
        klass.class_eval{ define_method(key){ value } }
      end
      klass.new
    end
  end
end
