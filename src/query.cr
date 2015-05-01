module ActiveRecord
  class Query
    include QueryObject

    def initialize(@expression)
    end

    def same_query?(other : Query)
      self.expression == other.expression
    end

    def same_query?(other)
      false
    end

    def or(other)
      binary_op(Or, other)
    end

    alias_method :|, :or

    def and(other)
      binary_op(And, other)
    end

    alias_method :&, :and

    def xor(other)
      binary_op(Xor, other)
    end

    alias_method :^, :xor

    def not
      unary_op(Not)
    end

    alias_method :!, :not

    def is_true
      unary_op(IsTrue)
    end

    def is_false
      unary_op(IsFalse)
    end

    def is_unknown
      unary_op(IsUnknown)
    end

    def is_null
      unary_op(IsNull)
    end

    def is_not_true
      unary_op(IsNotTrue)
    end

    def is_not_false
      unary_op(IsNotFalse)
    end

    def is_not_unknown
      unary_op(IsNotUnknown)
    end

    def is_not_null
      unary_op(IsNotNull)
    end

    getter expression

    private def binary_op(klass, other)
      Query.new(klass.new(self, other))
    end

    private def unary_op(klass)
      Query.new(klass.new(self))
    end

    class GenericExpression
      def initialize(@receiver, @argument)
      end

      def ==(other : GenericExpression)
        QueryObject.same_query?(self.receiver, other.receiver) &&
          QueryObject.same_query?(self.argument, other.argument)
      end

      def ==(other)
        false
      end

      getter receiver
      getter argument
    end

    class UnaryExpression
      def initialize(@receiver)
      end

      def ==(other : UnaryExpression)
        QueryObject.same_query?(self.receiver, other.receiver)
      end

      def ==(other)
        false
      end

      getter receiver
    end

    class Equal < GenericExpression
    end

    class NotEqual < GenericExpression
    end

    class Greater < GenericExpression
    end

    class GreaterEqual < GenericExpression
    end

    class Less < GenericExpression
    end

    class LessEqual < GenericExpression
    end

    class Or < GenericExpression
    end

    class And < GenericExpression
    end

    class Xor < GenericExpression
    end

    class Not < UnaryExpression
    end

    class IsTrue < UnaryExpression
    end

    class IsFalse < UnaryExpression
    end

    class IsUnknown < UnaryExpression
    end

    class IsNull < UnaryExpression
    end

    class IsNotTrue < UnaryExpression
    end

    class IsNotFalse < UnaryExpression
    end

    class IsNotUnknown < UnaryExpression
    end

    class IsNotNull < UnaryExpression
    end
  end
end
