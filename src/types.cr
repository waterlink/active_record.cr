module ActiveRecord
  macro define_not_null_for(type, name)
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

  macro register_type(kind, ty, default=nil, comparable=false, to_s="")
    {{kind.id}} {{ty.id}}
      def self.null_class
        Null
      end

      def ==(other : Null)
        self == {{default}}
      end

      {{kind.id}} Null
        {% if comparable %}include Comparable({{ty.id}}){% end %}

        def to_s(io)
          io << {{to_s}}
        end

        def ==(other : self)
          true
        end

        def ==(other)
          {{default}} == other
        end

        macro method_missing(name, args, block)
          {{default}}.\{{name.id}}(\{{args.argify}}) \{{block}}
        end
      {{:end.id}}

      {% if comparable %}
        include Comparable({{ty.id}})

        def <=>(other : Null)
          self <=> {{default}}
        end
      {% end %}
    {{:end.id}}
  end
end

ActiveRecord.register_type :struct, Int, default: 0, comparable: true
ActiveRecord.define_not_null_for(:struct, Int)
ActiveRecord.define_not_null_for(:struct, Int8)
ActiveRecord.define_not_null_for(:struct, UInt8)
ActiveRecord.define_not_null_for(:struct, Int16)
ActiveRecord.define_not_null_for(:struct, UInt16)
ActiveRecord.define_not_null_for(:struct, Int32)
ActiveRecord.define_not_null_for(:struct, UInt32)
ActiveRecord.define_not_null_for(:struct, Int64)
ActiveRecord.define_not_null_for(:struct, UInt64)

ActiveRecord.register_type :class, String, default: ""
ActiveRecord.define_not_null_for(:class, String)

ActiveRecord.register_type :struct, Time, default: Time.new(0), comparable: true
ActiveRecord.define_not_null_for(:struct, Time)

ActiveRecord.register_type :struct, Bool, default: false
ActiveRecord.define_not_null_for(:struct, Bool)

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
