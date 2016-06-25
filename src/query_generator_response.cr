require "./adapter"

module ActiveRecord
  abstract class QueryGenerator
    abstract class QueryProtocol
      abstract def query
      abstract def params

      def ==(other : QueryProtocol)
        self.query == other.query &&
          self.params == other.params
      end

      def ==(other)
        false
      end

      def hash
        {query, params}.hash
      end
    end

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

      def initialize(@query : QueryProtocol)
      end
    end
  end
end
