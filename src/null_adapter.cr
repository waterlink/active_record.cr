require "./active_record"

module ActiveRecord
  class NullAdapter < ActiveRecord::Adapter
    abstract class Query
      abstract def call(params, fields)
    end

    getter last_id
    getter records

    def self.reset
      adapters.each do |adapter|
        adapter._reset
      end
    end

    protected def self.adapters
      @@adapters ||= [] of self
    end

    def self.register_query(query, handler)
      registered_queries[query] = handler
    end

    protected def self.registered_query(query)
      registered_queries.fetch(query) do
        raise ArgumentError.new(
          "Unregistered query for NullAdapter: #{query.inspect}, use NullAdapter.register_query"
        )
      end
    end

    private def self.registered_queries
      @@registered_queries ||= {} of String => Query
    end

    def initialize(@table_name, register = true)
      @last_id = 0
      @records = [] of Hash(String, ActiveRecord::SupportedType)
      self.class.adapters << self if register
    end

    def read(primary_key)
      records[(primary_key as Int) - 1]
    end

    def create(fields, primary_field)
      @last_id += 1
      records << fields.dup.merge({ primary_field => last_id })
      last_id
    end

    def where(query_hash)
      records.select do |record|
        matches = true
        query_hash.each do |field, value|
          matches &&= record.fetch(field, value.class.null_class.new) == value
        end
        matches
      end
    end

    def where(query, params)
      records.select do |record|
        self.class.registered_query(query).call(params, record)
      end
    end

    def update(primary_key, fields)
      records[(primary_key as Int) - 1] = fields.dup
    end

    def _reset
      initialize(@table_name, false)
    end
  end

  Registry.register_adapter("null", NullAdapter)
end
