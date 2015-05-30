require "./criteria_helper"

module ActiveRecord
  class Model
    include CriteriaHelper
    extend CriteriaHelper

    macro null_object(name_and_super, &block)
      class {{name_and_super.receiver}} < {{name_and_super.args[0]}}
        {{block.body}}
      end

      def self.null_value
        {{name_and_super.receiver}}.new
      end
    end

    macro adapter(value)
      @@adapter_name = {{value.stringify}}
    end

    macro table_name(value)
      @@table_name = {{value.stringify}}
    end

    macro primary(field_declaration)
      @@primary_field = {{field_declaration.var.stringify}}
      field {{field_declaration}}
      _field primary_key, {{field_declaration}}
    end

    macro define_field_macro(level)
      macro _field(name, field_declaration)
        {{level.id}} def \{{name.id}}=(value : \{{field_declaration.type}})
          fields[\{{field_declaration.var.stringify}}] = value
        end

        {{level.id}} def \{{name.id}}
          fields.fetch(\{{field_declaration.var.stringify}}, \{{field_declaration.type}}::Null.new) as \{{field_declaration.type}}
        end
      end

      macro field(field_declaration)
        _field(\{{field_declaration.var}}, \{{field_declaration}})
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

    protected def self.primary_field
      @@primary_field
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

    def self.build(null : Nil)
      null_value
    end

    def self.build(hash : Hash(K, V))
      new(hash)
    end

    def ==(other)
      return false unless other.is_a?(Model)
      self.fields == other.fields
    end

    def self.read(primary_key)
      build(adapter.read(primary_key))
    end

    def create
      fields[self.class.primary_field] = self.class.adapter.create(
        fields, self.class.primary_field
      )
      self
    end

    def self.create(hash)
      new(hash).create
    end

    def self.create
      new.create
    end

    macro query_level(level)
      {{level.id}} def self.where(query_hash)
        adapter.where(query_hash).map { |fields| new(fields) }
      end

      {{level.id}} def self.where(query, params)
        adapter.where(query, params).map { |fields| new(fields) }
      end

      {{level.id}} def self.index
        adapter.index.map { |fields| new(fields) }
      end
    end

    query_level ""

    def update
      self.class.adapter.update(primary_key, fields)
      self
    end

    def delete
      self.class.adapter.delete(primary_key)
    end

    protected def fields
      @fields ||= {} of String => SupportedType
    end

    def self.null_value
      Null.new
    end

    class Null < Model
    end
  end
end
