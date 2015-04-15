require "./active_record"

module ActiveRecord
  class NullAdapter < ActiveRecord::Adapter
    getter last_id
    getter records

    def initialize(@table_name)
      @last_id = 0
      @records = [] of Hash(String, ActiveRecord::SupportedType)
    end

    def read(id)
      records[(id as Int) - 1]
    end

    def create(fields)
      @last_id += 1
      records << fields
      last_id
    end
  end

  Registry.register_adapter("null", NullAdapter)
end
