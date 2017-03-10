module ActiveRecord::Directives
  module HasMany
    macro has_many(foreign_model, query)
      def self.join(t : {{foreign_model}}.class)
        HasManyWrapper({{MACRO_CURRENT.last.id}})
          .new({{foreign_model}}.table_name_value, {{query}})
      end

      @cached_{{foreign_model.stringify.downcase.id}}s : Array({{foreign_model}})?

      def {{foreign_model.stringify.downcase.id}}s
        @cached_{{foreign_model.stringify.downcase.id}}s ||=
          fetch_{{foreign_model.stringify.downcase.id}}s
      end

      def fetch_{{foreign_model.stringify.downcase.id}}s
        query = ::Query::Equals[({{query}}).left, id]
        {{foreign_model}}.where(query)
      end
    end

    class HasManyWrapper(T)
      def initialize(@foreign_table_name : String, @query : ::Query::Query)
      end

      def all
        T.all
      end
    end
  end
end
