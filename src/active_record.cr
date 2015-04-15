require "./active_record/*"

struct Int
  struct Null < Int
    include Comparable(Int)

    def to_s(io)
      io << ""
    end

    def to_i64
      0
    end

    def inspect
      "Null(Int)"
    end

    def +(other)
      0 + other
    end

    def -(other)
      0 - other
    end

    def <=>(other)
      0 <=> other
    end
  end
end

class String
  class Null < String
    def inspect
      "Null(String)"
    end
  end
end

module ActiveRecord
  alias SupportedType = String|Int

  abstract class Adapter
    abstract def create(table_name, fields)
  end

  module Registry
    extend self

    def register_adapter(name, adapter)
      adapters[name] = adapter
    end

    def adapter(name)
      adapters[name]
    end

    def adapters
      @@adapters ||= {} of String => Adapter.class
    end
  end

  class Model
    macro adapter(value)
      @@adapter_name = {{value.stringify}}
    end

    macro table_name(value)
      @@table_name = {{value.stringify}}
    end

    macro primary(field_declaration)
      field {{field_declaration}}
    end

    macro define_field_macro(level)
      macro field(field_declaration)
        {{level.id}} def \{{field_declaration.var}}=(value : \{{field_declaration.type}})
          fields[\{{field_declaration.var.stringify}}] = value
        end

        {{level.id}} def \{{field_declaration.var}}
          fields.fetch(\{{field_declaration.var.stringify}}, \{{field_declaration.type}}::Null.new)
        end

        register_field(\{{field_declaration.var.stringify}})
      end
    end

    define_field_macro ""

    macro field_level(level)
      define_field_macro({{level}})
    end

    private def self.register_field(name)
      fields << name
    end

    def self.fields
      @@fields ||= [] of String
    end

    def self.read(id)
      new(adapter.read(id))
    end

    protected def self.adapter
      @@adapter ||= Registry.adapter(adapter_name).new(table_name_value)
    end

    private def self.adapter_name
      @@adapter_name
    end

    private def self.table_name_value
      @@table_name
    end

    def initialize(hash)
      hash.each do |field, value|
        fields[field] = value if self.class.fields.includes?(field)
      end
    end

    def initialize
    end

    def ==(other)
      return false unless other.is_a?(Model)
      self.fields == other.fields
    end

    def create
      fields["id"] = self.class.adapter.create(fields)
      self
    end

    def self.create(hash)
      new(hash).create
    end

    def self.create
      new.create
    end

    protected def fields
      @fields ||= {} of String => SupportedType
    end
  end
end
