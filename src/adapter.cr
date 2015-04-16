require "./types"

module ActiveRecord
  alias Fields = Hash(String, SupportedType)

  abstract class Adapter
    abstract def create(fields)
    abstract def read(id)
    abstract def where(query_hash)
    abstract def where(query, params)
    abstract def update(id, fields)
    abstract def delete(id)
  end
end
