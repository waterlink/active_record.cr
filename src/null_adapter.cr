require "./active_record"
require "./sql/query_generator"

module ActiveRecord
  class NullAdapter < ActiveRecord::Adapter
    abstract class Query
      abstract def call(params, fields)
    end

    abstract class JoinQuery
      abstract def call(base_record, foreign_record)
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

    def self.registered_query(query)
      registered_queries.fetch(query) do
        raise ArgumentError.new(
          "Unregistered query for NullAdapter: #{query.inspect}, use NullAdapter.register_query"
        )
      end
    end

    private def self.registered_queries
      @@registered_queries ||= {} of String => Query
    end

    def self.register_join_query(query, handler)
      registered_join_queries[query] = handler
    end

    def self.registered_join_query(query)
      registered_join_queries.fetch(query) do
        raise ArgumentError.new(
          "Unregistered join query for NullAdapter: #{query.inspect}, use NullAdapter.register_join_query"
        )
      end
    end

    private def self.registered_join_queries
      @@registered_join_queries ||= {} of String => JoinQuery
    end

    def self.build(table_name, primary_field, fields, register = true)
      new(table_name, primary_field, fields, register)
    end

    def initialize(@table_name : String, @primary_field : String, @fields : Array(String), register = true)
      @last_id = 0
      @records = [] of Hash(String, ActiveRecord::SupportedType)
      @deleted = [] of Int32
      self.class.adapters << self if register
    end

    def get(primary_key)
      return nil if deleted.includes?((primary_key.as(Int32)) - 1)
      records[(primary_key.as(Int32)) - 1]
    end

    def create(fields)
      @last_id += 1
      records << fields.dup.merge({primary_field => last_id})
      last_id
    end

    def all
      # FIXME: doesn't handle deleted entries
      records
    end

    def where(query : ::Query::Query)
      query = self.class.generate_query(query).not_nil!
      _where(query.query, query.params)
    end

    def where(query_hash : Hash(K, V)) forall K, V
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
      records[(primary_key.as(Int32)) - 1] = fields.dup
    end

    def delete(primary_key)
      deleted << (primary_key.as(Int32)) - 1
    end

    def with_joins(join_model, joins, foreign_adapter)
      NullJoinsAdapter.new(@table_name, @primary_field, @fields, join_model, joins, self, foreign_adapter)
    end

    def _reset
      initialize(@table_name, @primary_field, @fields, false)
    end
  end

  Registry.register_adapter("null", NullAdapter)

  class NullJoinsAdapter < ActiveRecord::JoinAdapter
    @join_query : QueryGenerator::QueryProtocol
    @foreign_table : String

    def initialize(
      @table_name : String,
      @primary_field : String,
      @fields : Array(String),
      @join_kind : String,
      @joins : Hash(String, ::Query::Query),
      @base_adapter : Adapter,
      @foreign_adapter : Adapter)

      @foreign_table = @joins.keys.first
      join_query = @joins[@foreign_table]
      @join_query = NullAdapter.generate_query(join_query).not_nil!
    end

    def get(id)
      base_record = @base_adapter.get(id)
      all_foreign_records = @foreign_adapter.all

      foreign_records = [] of Fields

      all_foreign_records.each_index do |index|
        record = all_foreign_records[index]
        matches = NullAdapter
          .registered_join_query(@join_query.query)
          .call(base_record, record)

        if matches && @join_kind == "one-to-many"
          foreign_records << record
        elsif matches && @join_kind == "one-to-one"
          return Join::Record.new(base_record, record)
        end
      end

      if @join_kind == "one-to-many"
        Join::Record.new(base_record, foreign_records)
      else
        return nil
      end
    end

    def all
      raise "TODO: all"
    end

    def where(query_hash : Hash(K, V)) forall K, V
      raise "TODO: where(hash)"
    end

    def where(query : ::Query::Query)
      raise "TODO: where(query)"
    end
  end
end
