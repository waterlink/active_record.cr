module ActiveRecord
  abstract class Adapter
    abstract def create(table_name, fields)
  end
end
