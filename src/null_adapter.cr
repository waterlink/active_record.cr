require "./active_record"
require "./sql/query_generator"

module ActiveRecord
  class NullAdapter < ActiveRecord::Adapter
    abstract class Query
      abstract def call(params, fields)
    end

    query_generator Sql::QueryGenerator.new

    getter last_id, records, deleted, primary_field, fields

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

    def self.build(table_name, primary_field, fields, register = true)
      new(table_name, primary_field, fields, register)
    end

    def initialize(@table_name, @primary_field, @fields, register = true)
      @last_id = 0
      @records = [] of Hash(String, ActiveRecord::SupportedType)
      @deleted = [] of Int32
      self.class.adapters << self if register
    end

    def get(primary_key)
      return nil if deleted.includes?((primary_key as Int32) - 1)
      records[(primary_key as Int32) - 1]
    end

    def create(fields)
      @last_id += 1
      records << fields.dup.merge({primary_field => last_id})
      last_id
    end

    def all
      records
    end

    def where(query : ActiveRecord::Query)
      query = self.class.generate_query(query).not_nil!
      _where(query.query, query.params)
    end

    def where(query_hash)
      result = [] of Fields

      records.each_index do |index|
        record = records[index]
        matches = !deleted.includes?(index)

        query_hash.each do |field, value|
          matches &&= record.fetch(field, value.class.null_class.new) == value
        end

        if matches
          result << record
        end
      end

      result
    end

    def _where(query, params)
      result = [] of Fields

      records.each_index do |index|
        record = records[index]
        matches = !deleted.includes?(index) &&
          self.class.registered_query(query).call(params, record)

        if matches
          result << record
        end
      end

      result
    end

    def update(primary_key, fields)
      records[(primary_key as Int32) - 1] = fields.dup
    end

    def delete(primary_key)
      deleted << (primary_key as Int32) - 1
    end

    def _reset
      initialize(@table_name, @primary_field, @fields, false)
    end
  end

  Registry.register_adapter("null", NullAdapter)
end
