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
      class Fail < ArgumentError
      end

      def generate(query, param_count = 0)
        value = _generate(query, param_count)
        ::ActiveRecord::QueryGenerator::Response.lift(value)
      rescue Fail
        ::ActiveRecord::QueryGenerator::Next.new
      end

      def _generate(query : ::Query::Criteria, param_count = 0)
        Query.new(query.name)
      end

      def _generate(query : ::Query::Equals(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " = ", param_count)
      end

      def _generate(query : ::Query::NotEquals(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " <> ", param_count)
      end

      def _generate(query : ::Query::MoreThan(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " > ", param_count)
      end

      def _generate(query : ::Query::MoreThanOrEqual(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " >= ", param_count)
      end

      def _generate(query : ::Query::LessThan(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " < ", param_count)
      end

      def _generate(query : ::Query::LessThanOrEqual(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " <= ", param_count)
      end

      def _generate(query : ::Query::Or(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " OR ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::In(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " IN ", param_count)
      end

      def _generate(query : ::Query::Xor(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " XOR ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::And(Q, T), param_count = 0) forall Q, T
        generate_binary_op(query, " AND ", param_count, parenthesis: true)
      end

      def _generate(query : ::Query::Not(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, prefix: "NOT ")
      end

      def _generate(query : ::Query::IsTrue(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS TRUE")
      end

      def _generate(query : ::Query::IsNotTrue(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT TRUE")
      end

      def _generate(query : ::Query::IsFalse(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS FALSE")
      end

      def _generate(query : ::Query::IsNotFalse(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT FALSE")
      end

      def _generate(query : ::Query::IsUnknown(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS UNKNOWN")
      end

      def _generate(query : ::Query::IsNotUnknown(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT UNKNOWN")
      end

      def _generate(query : ::Query::IsNull(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NULL")
      end

      def _generate(query : ::Query::IsNotNull(Q), param_count = 0) forall Q
        generate_unary_op(query, param_count, parenthesis: true, suffix: " IS NOT NULL")
      end

      def _generate(query : ::ActiveRecord::SupportedType, param_count = 0)
        param_count += 1
        Query.new(":#{param_count}", {"#{param_count}" => query})
      end

      def _generate(query : Array(T), param_count = 0) forall T
        result, param_count = ArrayQueryHandler.new { |name| ":#{name}" }.handle(query)
        result
      end

      def _generate(query : T, params_count) forall T
        raise Fail.new
      end

      private def generate_binary_op(query : ::Query::BiOperator(Q, T), separator, param_count, parenthesis = false) forall Q, T
        query_a = _generate(query.left, param_count)
        param_count += query_a.params.keys.size

        query_b = _generate(query.right, param_count)
        query_a.concat_with(separator, query_b, parenthesis)
      end

      private def generate_unary_op(query : ::Query::UOperator(Q), param_count, parenthesis = false, prefix = "", suffix = "") forall Q
        query_a = _generate(query.query, param_count)

        query_a.wrap_with(prefix, suffix, parenthesis)
      end
    end
  end
end
