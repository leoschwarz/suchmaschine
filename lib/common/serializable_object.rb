require 'oj'

module Common
  class SerializableObject
    def initialize(data = {})
      @_data = @@_fields.merge(data)
    end

    def serialize
      Oj.dump(@_data, {mode: :object})
    end

    def self.deserialize(json)
      return nil if json.nil?
      self.new(Oj.load(json, {mode: :object}))
    end

    def self.field(name, default=nil)
      @@_fields       = {} if not defined? @@_fields
      @@_fields[name] = default
      define_method("#{name}"){ instance_variable_get("@_data")[name] }
      define_method("#{name}="){ |value| instance_variable_get("@_data")[name] = value }
    end

    def self.fields(*names)
      names.each{|item| field(item)}
    end
  end
end
