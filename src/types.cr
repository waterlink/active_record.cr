macro active_record_define_not_null_for(type, name)
  {{type.id}} {{name.id}}
    def not_null! : {{name}}
      self as {{name}}
    end

    def null?
      false
    end

    {{type.id}} Null
      def not_null! : NoReturn
        ::raise ActiveRecord::NullCheckFailed.new("It is {{name.id}}::Null")
      end

      def inspect
        "Null(#{{{type.id.stringify}}})"
      end

      def null?
        true
      end
    {{:end.id}}
  {{:end.id}}
end

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

  def ==(other : Null)
    self == ""
  end

  class Null
    def to_s(io)
      io << ""
    end

    def ==(other : self)
      true
    end

    def ==(other : String)
      other == self
    end

    macro method_missing(name, args, block)
      "".{{name.id}}({{args.argify}}) {{block}}
    end
  end
end

struct Time
  def self.null_class
    Null
  end

  struct Null
    include Comparable(Time)

    def to_s(io)
      io << ""
    end

    macro method_missing(name, args, block)
      Time.new(0).{{name.id}}({{args.argify}}) {{block}}
    end
  end

  include Comparable(Null)

  def <=>(other : Null)
    self <=> Time.new(0)
  end
end

struct Bool
  def self.null_class
    Null
  end

  def ==(other : Null)
    false
  end

  struct Null
    def to_s(io)
      io << ""
    end

    def ==(other : self)
      true
    end

    def ==(other)
      false
    end

    macro method_missing(name, args, block)
      false.{{name.id}}({{args.argify}}) {{block}}
    end
  end
end

active_record_define_not_null_for(:struct, Int)

active_record_define_not_null_for(:struct, Int8)
active_record_define_not_null_for(:struct, UInt8)
active_record_define_not_null_for(:struct, Int16)
active_record_define_not_null_for(:struct, UInt16)
active_record_define_not_null_for(:struct, Int32)
active_record_define_not_null_for(:struct, UInt32)
active_record_define_not_null_for(:struct, Int64)
active_record_define_not_null_for(:struct, UInt64)

active_record_define_not_null_for(:class, String)

active_record_define_not_null_for(:struct, Time)

active_record_define_not_null_for(:struct, Bool)

module ActiveRecord
  alias IntTypes = Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64 | Int::Null
  alias StringTypes = String | String::Null
  alias TimeTypes = Time | Time::Null
  alias SupportedTypeWithoutString = Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64 | Int::Null | Time | Time::Null | Bool | Bool::Null
  alias BoolTypes = Bool | Bool::Null
  alias SupportedType = StringTypes | SupportedTypeWithoutString
  alias NonNullType = String | Int8 | Int32 | Int16 | Int64 | UInt8 | UInt32 | UInt16 | UInt64 | Time | Bool

  class NullCheckFailed < Exception; end
end
