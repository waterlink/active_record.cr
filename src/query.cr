module ActiveRecord
  class Query
    include QueryObject

    def initialize(@condition)
    end

    def same_query?(other : Query)
      self.condition == other.condition
    end

    def same_query?(other)
      false
    end

    getter condition

    class GenericCondition
      def initialize(@receiver, @argument)
      end

      def ==(other : GenericCondition)
        QueryObject.same_query?(self.receiver, other.receiver) &&
          QueryObject.same_query?(self.argument, other.argument)
      end

      def ==(other)
        false
      end

      protected getter receiver
      protected getter argument
    end

    class Equal < GenericCondition
    end
  end
end
