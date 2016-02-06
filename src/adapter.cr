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
    extend AdapterHelper

    def self.build(table_name, primary_field, fields, register = true)
      raise "ActiveRecord::Adapter requires 'self.build(table_name, primary_field, fields, register = true)' to be implemented"
    end

    abstract def create(fields)
    abstract def get(id)
    abstract def all
    abstract def where(query_hash : Hash)
    abstract def where(query : Query)
    abstract def update(id, fields)
    abstract def delete(id)
  end
end
