############################################################################################
# Das Serializable-Modul ist ein Mixin welches mithilfe des "include"-Befehls in eine      #
# Klasse geladen werden kann und dann die Logik anbietet ein Objekt serialisierbar zu      #
# machen. Es werden eine Klassenmethode namens field und fields definiert, welche es       #
# ermöglichen Felder und Standardwerte auf Klassenebene zu definieren.                     #
# Eine Klassenmethode namens "deserialize" ermöglicht es ein ehemals mit der Instanz-      #
# methode "serialize" serialisiertes Objekt wieder in ein neues Objekt zu laden.           #
#                                                                                          #
# Für die Serialisierung wird die JSON Parser-Bibliothek "oj" verwendet. Der Aufbau des    #
# Mixins baut auf demjenigen folgendes Aritkels auf:                                       #
# http://wiseheartdesign.com/articles/2006/09/22/class-level-instance-variables/           #
############################################################################################
require 'oj'

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
