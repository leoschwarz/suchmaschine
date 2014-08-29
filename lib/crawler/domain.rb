require 'date'

module Crawler
  class Domain
    attr_reader :name
  
    def initialize(name)
      @name = name
    end
    
    # Hilfsmethode um den Domain Namen einer URL zu extrahieren.
    def self.domain_name_of(url)
      match = /https?:\/\/([a-zA-Z0-9\.-]+)/.match(url)
      if not match.nil?
        domain_name = match[1].downcase
      else
        return nil
      end
    end
  end
end