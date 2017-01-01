module ActiveRecord
  module Sql
    class Query < QueryGenerator::QueryProtocol
      class EmptyParams
        def self.build
          {} of String => ::ActiveRecord::SupportedType
        end
      end

      EMPTY_PARAMS = EmptyParams.build

      getter query
      getter params

      @params : Hash(String, ::ActiveRecord::SupportedType)

      def self.[](*args)
        new(*args)
      end

      def initialize(@query : String, params = nil)
        @params = EmptyParams.build
        (params || EMPTY_PARAMS).each do |key, value|
          @params[key] = value
        end
      end

      def concat_with(separator, other, parenthesis)
        Query.new("#{self.query(parenthesis)}#{separator}#{other.query(parenthesis)}",
          self.params.merge(other.params))
      end

      def wrap_with(prefix, suffix, parenthesis)
        Query.new("#{prefix}#{query(parenthesis)}#{suffix}", params)
      end

      protected def query(parenthesis)
        return query unless parenthesis
        "(#{query})"
      end
    end

    class ArrayQueryHandler
      def initialize(&@param_name_transformer : Int32 -> String)
      end

      def handle(query : Array(T), param_count = 0) forall T
        params = {} of String => T
        query = query.map do |value|
          param_count += 1
          params[param_count.to_s] = value
          @param_name_transformer.call(param_count)
        end.join(", ")
        {Query.new("(#{query})", params), param_count}
      end
    end

    class QueryGenerator < ::ActiveRecord::QueryGenerator
      BINARY_QUERIES = {
        "Equals" => {separator: " = "},
        "NotEquals" => {separator: " <> "},
        "MoreThan" => {separator: " > "},
        "MoreThanOrEqual" => {separator: " >= "},
        "LessThan" => {separator: " < "},
        "LessThanOrEqual" => {separator: " <= "},
        "And" => {separator: " AND ", parenthesis: true},
        "Or" => {separator: " OR ", parenthesis: true},
        "Xor" => {separator: " XOR ", parenthesis: true},
        "In" => {separator: " IN "},
      }

      UNARY_QUERIES = {
        "Not" => {prefix: "NOT ", parenthesis: true},
        "IsTrue" => {suffix: " IS TRUE", parenthesis: true},
        "IsNotTrue" => {suffix: " IS NOT TRUE", parenthesis: true},
        "IsFalse" => {suffix: " IS FALSE", parenthesis: true},
        "IsNotFalse" => {suffix: " IS NOT FALSE", parenthesis: true},
        "IsUnknown" => {suffix: " IS UNKNOWN", parenthesis: true},
        "IsNotUnknown" => {suffix: " IS NOT UNKNOWN", parenthesis: true},
        "IsNull" => {suffix: " IS NULL", parenthesis: true},
        "IsNotNull" => {suffix: " IS NOT NULL", parenthesis: true},
      }

      class Fail < ArgumentError
      end

      def generate(query, param_count = 0)
        value = _generate(query, param_count)
        ::ActiveRecord::QueryGenerator::Response.lift(value)
      rescue Fail
        ::ActiveRecord::QueryGenerator::Next.new
      end

      def _generate(query : ::Query::Query, param_count = 0)
        name = query.query_name

        return Query.new("true") if name == "EMPTY_QUERY"
        return Query.new(query.name.as String) if query.is_a?(::Query::Criteria)

        if BINARY_QUERIES.has_key?(name)
          return generate_binary_op(query, BINARY_QUERIES[name], param_count)
        end

        if UNARY_QUERIES.has_key?(name)
          return generate_unary_op(query, UNARY_QUERIES[name], param_count)
        end

        raise Fail.new
      end

      def _generate(query : ::ActiveRecord::SupportedType, param_count = 0)
        param_count += 1
        Query.new(":#{param_count}", {"#{param_count}" => query})
      end

      def _generate(query : Array(T), param_count = 0) forall T
        result, param_count = ArrayQueryHandler.new { |name| ":#{name}" }.handle(query)
        result
      end

      def _generate(query : Nil, param_count)
        raise Fail.new
      end

      def _generate(query : T, param_count) forall T
        raise Fail.new
      end

      private def query_or_value(x)
        if x.is_a?(::Query::Any)
          return x.value
        end

        x
      end

      private def generate_binary_op(query : ::Query::Query, options, param_count)
        separator = options.fetch(:separator, "")
        parenthesis = options.fetch(:parenthesis, false)

        left = query_or_value(query.left)
        query_a = _generate(left, param_count)
        param_count += query_a.params.keys.size

        right = query_or_value(query.right)
        query_b = _generate(right, param_count)
        query_a.concat_with(separator, query_b, parenthesis)
      end

      private def generate_unary_op(query : ::Query::Query, options, param_count)
        prefix = options.fetch(:prefix, "")
        suffix = options.fetch(:suffix, "")
        parenthesis = options.fetch(:parenthesis, false)

        subquery = query_or_value(query.left)
        query_a = _generate(subquery, param_count)

        query_a.wrap_with(prefix, suffix, parenthesis)
      end
    end
  end
end
