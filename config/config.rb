require 'hashr'
require 'yaml'


def load_configuration(module_ref, file_name)
  unless module_ref.method_defined? :config
    file_path = "config/#{file_name}"
    data      = YAML.load(File.read(file_path))
    
    environment = ENV["LIGHTBLAZE_ENV"]
    if environment.nil?
      puts "Warnung: Die Umgebungsvariable 'LIGHTBLAZE_ENV' ist nicht definiert. Der Standardwert 'development' wurde angenommen."
      environment = "development"
    end
    
    module_ref.class_variable_set(:@@config, Hashr.new(data[environment]))
    module_ref.send :define_singleton_method, :config do
      self.class_variable_get(:@@config)
    end
  end
end

