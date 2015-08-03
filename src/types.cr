struct Int
  def self.null_class
    Null
  end

  struct Null
    include Comparable(Int)

    def to_s(io)
      io << ""
    end

    macro method_missing(name, args, block)
      0.{{name.id}}({{args.argify}}) {{block}}
    end
  end

  include Comparable(Null)

  def <=>(other : Null)
    self <=> 0
  end
end

class String
  def self.null_class
    Null
  end

  class Null
    def to_s(io)
      io << ""
    end

    def inspect
      "Null(String)"
    end

    macro method_missing(name, args, block)
      "".{{name.id}}({{args.argify}}) {{block}}
    end
  end
end

module ActiveRecord
  alias IntTypes = Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Int::Null
  alias StringTypes = String|String::Null
  alias SupportedTypeWithoutString = Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Int::Null
  alias SupportedType = StringTypes|SupportedTypeWithoutString
end
