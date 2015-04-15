struct Int
  struct Null < Int
    include Comparable(Int)

    def to_s(io)
      io << ""
    end

    def to_i64
      0
    end

    def inspect
      "Null(Int)"
    end

    def +(other)
      0 + other
    end

    def -(other)
      0 - other
    end

    def <=>(other)
      0 <=> other
    end
  end
end

class String
  class Null < String
    def inspect
      "Null(String)"
    end
  end
end

module ActiveRecord
  alias SupportedType = String|Int
end
