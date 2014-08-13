require 'hashr'
require 'yaml'

module Crawler
  class << self
    def config
      if not defined? @@config or @@config.nil?
        h = YAML.load(File.read("config/config.yml"))
        environment = ENV["LIGHTBLAZE_ENV"]
        if environment.nil?
          puts "Warning, no environment specified. Assuming development."
          environment = "development"
        end
        
        @@config = Hashr.new(h[environment])
      end
      @@config
    end    
  end
end