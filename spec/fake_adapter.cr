require "singleton"

class FakeAdapter < ActiveRecord::Adapter
  getter adapter, table_name, primary_field, fields

  @@table_name : String?
  @@primary_field : String?
  @@fields : Array(String)?
  @@register : Bool?

  def initialize(@table_name : String, @primary_field : String, @fields : Array(String), register = true)
    @adapter = ActiveRecord::NullAdapter.new(table_name.not_nil!, primary_field, fields, register)
  end

  def initialize
    initialize(@@table_name.not_nil!, @@primary_field.not_nil!, @@fields.not_nil!, @@register.not_nil!)
  end

  def self.instance
    Singleton.instance_of(self)
  end

  def self._reset
    Singleton.reset
  end

  def self.build(table_name, primary_field, fields, register = true)
    @@table_name = table_name
    @@primary_field = primary_field
    @@fields = fields
    @@register = register
    instance
  end

  macro delegate(to, method)
    def {{method}}
      {{to}}.{{method}}
    end
  end

  delegate adapter, create(fields)
  delegate adapter, get(id)
  delegate adapter, all
  delegate adapter, where(query_hash)
  delegate adapter, where(query, params)
  delegate adapter, update(id, fields)
  delegate adapter, delete(id)
end

ActiveRecord::Registry.register_adapter("fake", FakeAdapter)
