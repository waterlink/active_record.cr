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

    abstract def self.build(table_name, primary_field, fields, register = true)
    abstract def create(fields)
    abstract def find(id)
    abstract def index
    abstract def where(query_hash)
    abstract def where(query, params)
    abstract def update(id, fields)
    abstract def delete(id)
  end
end
