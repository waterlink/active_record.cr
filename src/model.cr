require "./criteria_helper"
require "./support"

module ActiveRecord
  class Model

    class Fields
      class Int
        getter fields

        def initialize
          @fields = {} of ::String => IntTypes
        end

        def set_field(name, value)
          if value.is_a?(::Int)
            fields[name] = value
          end
          value
        end
      end

      class String
        getter fields

        def initialize
          @fields = {} of ::String => ::String
        end

        def set_field(name, value)
          if value.is_a?(::String)
            fields[name] = value
          end
          value
        end
      end

      private getter typed_fields

      def initialize
        @typed_fields = {
          "Int" => Int.new,
          "String" => String.new,
        }
      end

      def [](its_type)
        typed_fields[its_type]
      end

      def to_h
        hash = {} of ::String => SupportedType

        typed_fields.each do |its_type, typed_fields|
          typed_fields.fields.each do |name, value|
            hash[name] = value
          end
        end

        hash
      end
    end

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
          typed_fields = fields[\{{field_declaration.type.stringify}}] as ::ActiveRecord::Model::Fields::\{{field_declaration.type.id}}
          typed_fields.fields[\{{field_declaration.var.stringify}}] = value
        end

        {{level.id}} def \{{name.id}}
          typed_fields = fields[\{{field_declaration.type.stringify}}] as ::ActiveRecord::Model::Fields::\{{field_declaration.type.id}}
          typed_fields.fields.fetch(\{{field_declaration.var.stringify}}, \{{field_declaration.type}}::Null.new)
        end
      end

      macro field(field_declaration)
        _field(\{{field_declaration.var}}, \{{field_declaration}})
        register_field(\{{field_declaration.var.stringify}}, \{{field_declaration.type.stringify}})
      end
    end

    define_field_macro ""

    macro field_level(level)
      define_field_macro({{level}})
    end

    private def self.register_field(name, its_type)
      fields << name
      field_types[name] = its_type
    end

    def self.fields
      @@fields ||= [] of String
    end

    def self.field_types
      @@field_types ||= {} of String => String
    end

    protected def self.primary_field
      @@primary_field
    end

    protected def self.adapter
      @@adapter ||= Registry.adapter(adapter_name).build(table_name_value, primary_field, fields)
    end

    private def self.adapter_name
      @@adapter_name
    end

    private def self.table_name_value
      (@@table_name ||= Support.plural(name)).not_nil!
    end

    def initialize(hash)
      hash.each do |field, value|
        set_field(field, value)
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
      self.fields.to_h == other.fields.to_h
    end

    def self.find(primary_key)
      build(adapter.find(primary_key)) as self
    end

    def create
      set_field(
        self.class.primary_field,
        self.class.adapter.create(fields.to_h),
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
      self.class.adapter.update(primary_key, fields.to_h)
      self
    end

    def delete
      self.class.adapter.delete(primary_key)
    end

    protected def fields
      @fields ||= Fields.new
    end

    private def set_field(field, value)
      return unless self.class.fields.includes?(field)
      fields[self.class.field_types[field]]
        .set_field(field, value)
    end

    def self.null_value
      Null.new
    end

    class Null < Model
    end
  end
end
