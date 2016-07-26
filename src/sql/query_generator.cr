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

      def handle(query : Array(T), param_count = 0)
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
      class Fail < ArgumentError
      end

      def generate(query : ::ActiveRecord::SupportedType, param_count = 0)
        _handle(query, param_count)
      end

      def generate(query : ::Query::Query, param_count = 0)
        _handle(query, param_count)
      end

      def generate(query, param_count = 0)
        ::ActiveRecord::QueryGenerator::Next.new
      end

      def _handle(query, param_count = 0)
        ::ActiveRecord::QueryGenerator::Response.lift(_generate(query, param_count))
      rescue Fail
        ::ActiveRecord::QueryGenerator::Next.new
      end

      def _generate(query : ::Query::Criteria, param_count = 0)
        Query.new(query.name)
      end

      def _generate(query : ::Query::Equals(T), param_count = 0)
        generate_binary_op(query, " = ", param_count)
      end

      def _generate(query : ::Query::NotEquals, param_count = 0)
        generate_binary_op(query, " <> ", param_count)
      end

      def _generate(query : ::Query::MoreThan, param_count = 0)
        generate_binary_op(query, " > ", param_count)
      end

      def _generate(query : ::Query::MoreThanOrEqual, param_count = 0)
        generate_binary_op(query, " >= ", param_count)
      end

      def _generate(query : ::Query::LessThan, param_count = 0)
        generate_binary_op(query, " < ", param_count)
      end

      def _generate(query : ::Query::LessThanOrEqual, param_count = 0)
        generate_binary_op(query, " <= ", param_count)
      end

      def _generate(query : ::Query::Or, param_count = 0)
        generate_binary_op(query, " OR ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::In, param_count = 0)
        generate_binary_op(query, " IN ", param_count)
      end

      def _generate(query : ::Query::Xor, param_count = 0)
        generate_binary_op(query, " XOR ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::And, param_count = 0)
        generate_binary_op(query, " AND ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::Not, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, prefix: "NOT ")
      end

      def _generate(query : ::Query::IsTrue, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS TRUE")
      end

      def _generate(query : ::Query::IsNotTrue, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT TRUE")
      end

      def _generate(query : ::Query::IsFalse, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS FALSE")
      end

      def _generate(query : ::Query::IsNotFalse, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT FALSE")
      end

      def _generate(query : ::Query::IsUnknown, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS UNKNOWN")
      end

      def _generate(query : ::Query::IsNotUnknown, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT UNKNOWN")
      end

      def _generate(query : ::Query::IsNull, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NULL")
      end

      def _generate(query : ::Query::IsNotNull, param_count = 0)
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT NULL")
      end

      def _generate(query : ::ActiveRecord::SupportedType, param_count = 0)
        param_count += 1
        Query.new(":#{param_count}", {"#{param_count}" => query})
      end

      def _generate(query : Array(T), param_count = 0)
        result, param_count = ArrayQueryHandler.new { |name| ":#{name}" }.handle(query)
        result
      end

      def _generate(query, params_count)
        raise Fail.new
      end

      private def generate_binary_op(query, separator, param_count, parenthesis = false)
        query_a = _generate(query.left, param_count)
        param_count += query_a.params.keys.size

        query_b = _generate(query.right, param_count)
        query_a.concat_with(separator, query_b, parenthesis)
      end

      private def generate_unary_op(query, param_count, parenthesis = false, prefix = "", suffix = "")
        query_a = _generate(query.query, param_count)

        query_a.wrap_with(prefix, suffix, parenthesis)
      end
    end
  end
end
