require 'hashr'
require 'yaml'

module Crawler
  class << self
    def config
      if not defined? @@config or @@config.nil?
        h = YAML.load(File.read("config/crawler.yml"))
        environment = ENV["LIGHTBLAZE_ENV"]
        if environment.nil?
          puts "Warnung: Die Umgebungsvariable 'LIGHTBLAZE_ENV' ist nicht definiert. Der Standardwert 'development' wurde angenommen."
          environment = "development"
        end
        
        @@config = Hashr.new(h[environment])
      end
      @@config
    end    
  end
end