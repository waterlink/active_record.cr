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
  end

  class Criteria
    include QueryObject

    def self.build(name)
      Registry.fetch(name)
    end

    def initialize(@name)
    end

    def ==(other)
      Query.new(Query::Equal.new(self, other))
    end

    def same_query?(other : Criteria)
      self.name == other.name
    end

    def same_query?(other)
      false
    end

    protected getter name

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
