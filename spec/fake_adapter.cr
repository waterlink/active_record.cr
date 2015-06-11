class FakeAdapter < ActiveRecord::Adapter
  getter table_name
  getter adapter

  def initialize(@table_name, register = true)
    @adapter = ActiveRecord::NullAdapter.new(table_name.not_nil!, register)
  end

  def self.instance
    @@instance.not_nil!
  end

  def self._reset
    @@instance = nil
  end

  def self.build(table_name, register = true)
    (@@instance ||= new(table_name, register)).not_nil!
  end

  macro delegate(to, method)
    def {{method}}
      {{to}}.{{method}}
    end
  end

  delegate adapter, create(fields, primary_field)
  delegate adapter, read(id)
  delegate adapter, index
  delegate adapter, where(query_hash)
  delegate adapter, where(query, params)
  delegate adapter, update(id, fields)
  delegate adapter, delete(id)
end

ActiveRecord::Registry.register_adapter("fake", FakeAdapter)
