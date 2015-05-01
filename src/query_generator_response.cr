require "./adapter"

module ActiveRecord
  abstract class QueryGenerator
    abstract class Response
      def match(klass)
        return unless klass == self.class
        yield(self)
      end

      def self.lift(value)
        return value if value.is_a?(self)
        GeneratedQuery.new(value)
      end

      def query
      end
    end

    class Next < Response
    end

    class GeneratedQuery < Response
      getter query

      def initialize(@query)
      end
    end
  end
end
