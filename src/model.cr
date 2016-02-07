require "./criteria_helper"
require "./support"

require "pool/connection"

class ActiveRecord::Model; end

require "./model/fields"

module ActiveRecord
  class RecordNotFoundException < Exception
  end

  class Model
    include CriteriaHelper
    extend CriteriaHelper

    MACRO_CURRENT = [] of String

    DEFAULT_CONNECTION_POOL_CAPACITY = 1
    DEFAULT_CONNECTION_POOL_TIMEOUT = 2.0

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
        \{% MACRO_FIELDS_{{MACRO_CURRENT.last.id}} << name %}

        {{level.id}} def \{{name.id}}=(value : \{{field_declaration.type}})
          typed_fields = fields[\{{field_declaration.type.stringify}}] as ::ActiveRecord::Model::Fields::\{{field_declaration.type.id}}
          typed_fields.fields[\{{field_declaration.var.stringify}}] = value
        end

        {{level.id}} def \{{name.id}}
          typed_fields = fields[\{{field_declaration.type.stringify}}] as ::ActiveRecord::Model::Fields::\{{field_declaration.type.id}}
          typed_fields.fields.fetch(\{{field_declaration.var.stringify}}, \{{field_declaration.type}}::Null.new)
        end

        def _raw_fields
          {
            \{% for name in MACRO_FIELDS_{{MACRO_CURRENT.last.id}} %}
              \{{name.stringify}} => \{{name.id}},
            \{% end %}
          } of ::String => ::ActiveRecord::SupportedType
        end
      end

      macro field(field_declaration)
        _field(\{{field_declaration.var}}, \{{field_declaration}})
        register_field(\{{field_declaration.var.stringify}}, \{{field_declaration.type.stringify}})
      end
    end

    macro field_level(level)
      define_field_macro({{level}})
    end

    macro initialize_model(current_model)
      {% MACRO_CURRENT << current_model %}
      MACRO_FIELDS_{{current_model.id}} = [] of String
      define_field_macro ""
    end

    macro inherited
      initialize_model({{@type.name.id.stringify.gsub(/:/, "__")}})
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

    def self.connection_pool_capacity
      @@connection_pool_capacity ||= DEFAULT_CONNECTION_POOL_CAPACITY
    end

    def self.connection_pool_timeout
      @@connection_pool_timeout ||= DEFAULT_CONNECTION_POOL_TIMEOUT
    end

    protected def self.primary_field
      @@primary_field
    end

    protected def self.pool
      @@pool ||= ConnectionPool(Adapter).new(connection_pool_capacity, connection_pool_timeout) do
        Registry.adapter(adapter_name).build(table_name_value, primary_field, fields)
      end
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
      self._raw_fields == other._raw_fields
    end

    def self.get(primary_key)
      pool.connection do |adapter|
        if adapter.get(primary_key)
          build(adapter.get(primary_key)) as self
        else
          raise RecordNotFoundException.new("Record not found with given id.")
        end
      end
    end

    def self.[](primary_key)
      get(primary_key)
    end

    def create
      self.class.pool.connection do |adapter|
        set_field(
          self.class.primary_field,
          adapter.create(fields.to_h),
        )
        self
      end
    end

    def self.create(hash)
      new(hash).create
    end

    def self.create
      new.create
    end

    macro query_level(level)
      {{level.id}} def self.where(query_hash)
        pool.connection do |adapter|
          adapter.where(query_hash).map { |fields| new(fields) }
        end
      end

      {{level.id}} def self.where(query, params)
        pool.connection do |adapter|
          adapter.where(query, params).map { |fields| new(fields) }
        end
      end

      {{level.id}} def self.all
        pool.connection do |adapter|
          adapter.all.map { |fields| new(fields) }
        end
      end
    end

    query_level ""

    def update
      self.class.pool.connection do |adapter|
        adapter.update(primary_key, fields.to_h)
        self
      end
    end

    def delete
      self.class.pool.connection do |adapter|
        adapter.delete(primary_key)
      end
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
