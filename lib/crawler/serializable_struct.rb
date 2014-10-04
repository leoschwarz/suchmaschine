require 'oj'

module Crawler
  class SerializableStruct
    def initialize(data={})
      @data = data
    end
    
    def method_missing(method, *args, &block)
      if args.size == 1 and method[-1] == "="
        _set(method[0..-2].to_sym, args[0])
      elsif args.size == 0
        _get(method)
      else
        super
      end
    end
    
    def serialize
      Oj.dump(@data, {mode: :object})
    end
    
    def self.deserialize(json)
      new(Oj.load(json, {mode: :object}))
    end
    
    private
    def _get(key)
      @data[key]
    end
    
    def _set(key, value)
      @data[key] = value
    end
  end
end