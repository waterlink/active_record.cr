require "./types"
require "./adapter_helper"
require "./query_generator_response"

module ActiveRecord
  alias Fields = Hash(String, SupportedType)

  abstract class QueryGenerator
    # Either GeneratedQuery(QueryType) or Next
    abstract class Response
    end

    abstract def generate(query, param_count) : Response

    def used(klass)
    end
  end

  abstract class Adapter
    @@query_generators = Array(QueryGenerator).new
    extend AdapterHelper

    def self.build(table_name, primary_field, fields, register = true)
      raise "ActiveRecord::Adapter requires 'self.build(table_name, primary_field, fields, register = true)' to be implemented"
    end

    abstract def create(fields)
    abstract def get(id)
    abstract def all
    abstract def where(query_hash : Hash(K, V)) forall K, V
    abstract def where(query : ::Query::Query)
    abstract def update(id, fields)
    abstract def delete(id)

    abstract def with_joins(join_model, joins, foreign_adapter)
  end

  abstract class JoinAdapter
    abstract def get(id)
    abstract def all
    abstract def where(query_hash : Hash(K, V)) forall K, V
    abstract def where(query : ::Query::Query)
  end
end
