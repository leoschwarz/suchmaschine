require 'oj'

# URL: http://wiseheartdesign.com/articles/2006/09/22/class-level-instance-variables/

module Common
  module Serializable
    def self.included(base)
      base.extend ClassMethods
      base.include InstanceMethods
      base.instance_variable_set("@_fields", {})
    end
  
    module InstanceMethods
      def initialize(data = {})
        @_data = self.class.instance_variable_get("@_fields").merge(data)
      end

      def serialize
        Oj.dump(@_data, {mode: :object})
      end
    end
  
    module ClassMethods
      def deserialize(json)
        return nil if json.nil?
        self.new(Oj.load(json, {mode: :object}))
      end

      def field(name, default=nil)
        @_fields       = {} if not defined? @_fields
        @_fields[name] = default
        define_method("#{name}"){ instance_variable_get("@_data")[name] }
        define_method("#{name}="){ |value| instance_variable_get("@_data")[name] = value }
      end

      def fields(*names)
        names.each{|item| field(item)}
      end
    end
  end
end
