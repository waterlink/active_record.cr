module ActiveRecord
  class Query(T)
    include QueryObject

    macro alias_operation(new_name, name)
      def {{new_name.id}}(*args)
        {{name.id}}(*args)
      end
    end

    def initialize(@expression : T)
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

    def in(other)
      binary_op(In, other)
    end

    alias_operation :|, :or

    def and(other)
      binary_op(And, other)
    end

    alias_operation :&, :and

    def xor(other)
      binary_op(Xor, other)
    end

    alias_operation :^, :xor

    def not
      unary_op(Not)
    end

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

    class GenericExpression(T, K)
      def initialize(@receiver : T, @argument : K)
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

    class UnaryExpression(T)
      def initialize(@receiver : T)
      end

      def ==(other : UnaryExpression)
        QueryObject.same_query?(self.receiver, other.receiver)
      end

      def ==(other)
        false
      end

      getter receiver
    end

    class Equal(T, K) < GenericExpression(T, K)
    end

    class NotEqual(T, K) < GenericExpression(T, K)
    end

    class Greater(T, K) < GenericExpression(T, K)
    end

    class GreaterEqual(T, K) < GenericExpression(T, K)
    end

    class Less(T, K) < GenericExpression(T, K)
    end

    class LessEqual(T, K) < GenericExpression(T, K)
    end

    class Or(T, K) < GenericExpression(T, K)
    end

    class And(T, K) < GenericExpression(T, K)
    end

    class Xor(T, K) < GenericExpression(T, K)
    end

    class In(T, K) < GenericExpression(T, K)
    end

    class Not(T) < UnaryExpression(T)
    end

    class IsTrue(T) < UnaryExpression(T)
    end

    class IsFalse(T) < UnaryExpression(T)
    end

    class IsUnknown(T) < UnaryExpression(T)
    end

    class IsNull(T) < UnaryExpression(T)
    end

    class IsNotTrue(T) < UnaryExpression(T)
    end

    class IsNotFalse(T) < UnaryExpression(T)
    end

    class IsNotUnknown(T) < UnaryExpression(T)
    end

    class IsNotNull(T) < UnaryExpression(T)
    end
  end
end
