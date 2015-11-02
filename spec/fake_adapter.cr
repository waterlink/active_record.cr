class FakeAdapter < ActiveRecord::Adapter
  getter adapter, table_name, primary_field, fields

  def initialize(@table_name, @primary_field, @fields, register = true)
    @adapter = ActiveRecord::NullAdapter.new(table_name.not_nil!, primary_field, fields, register)
  end

  def self.instance
    @@instance.not_nil!
  end

  def self._reset
    @@instance = nil
  end

  def self.build(table_name, primary_field, fields, register = true)
    (@@instance ||= new(table_name, primary_field, fields, register)).not_nil!
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
