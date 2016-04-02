module ActiveRecord
  module QueryObject
    def self.same_query?(left : QueryObject, right)
      left.same_query?(right)
    end

    def self.same_query?(left, right : QueryObject)
      right.same_query?(left)
    end

    def self.same_query?(left, right)
      left == right
    end

    abstract def expression
  end

  class Criteria
    include QueryObject

    def self.build(name)
      Registry.fetch(name)
    end

    def initialize(@name)
    end

    def expression
      self
    end

    def ==(other)
      binary_op(Query::Equal, other)
    end

    def !=(other)
      binary_op(Query::NotEqual, other)
    end

    def >(other)
      binary_op(Query::Greater, other)
    end

    def >=(other)
      binary_op(Query::GreaterEqual, other)
    end

    def <(other)
      binary_op(Query::Less, other)
    end

    def <=(other)
      binary_op(Query::LessEqual, other)
    end

    def in(other)
      binary_op(Query::In, other)
    end

    def is_true
      unary_op(Query::IsTrue)
    end

    def is_false
      unary_op(Query::IsFalse)
    end

    def is_unknown
      unary_op(Query::IsUnknown)
    end

    def is_null
      unary_op(Query::IsNull)
    end

    def is_not_true
      unary_op(Query::IsNotTrue)
    end

    def is_not_false
      unary_op(Query::IsNotFalse)
    end

    def is_not_unknown
      unary_op(Query::IsNotUnknown)
    end

    def is_not_null
      unary_op(Query::IsNotNull)
    end

    def same_query?(other : Criteria)
      self.name == other.name
    end

    def same_query?(other)
      false
    end

    def to_s
      name
    end

    protected getter name

    private def binary_op(klass, other)
      Query.new(klass.new(self, other))
    end

    private def unary_op(klass)
      Query.new(klass.new(self))
    end

    module Registry
      extend self

      @@criterias = {} of String => Criteria

      def fetch(name)
        @@criterias[name] ||= Criteria.new(name)
      end

      def criterias
        @@criterias
      end
    end
  end
end
