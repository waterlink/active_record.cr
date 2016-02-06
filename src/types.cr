module ActiveRecord
  SPEC_TYPES = [] of Int32
  TYPE_GROUPS = [] of Int32

  macro alias_types(group, special=false, as=nil)
    {% as = "#{group.id}Types".id unless as %}
    {% TYPE_GROUPS << group unless special %}

    alias {{as.id}} =
      {% for x in SPEC_TYPES %}
        {% if x[0].id == group.id %}
          {% SPEC_TYPES << {"*Supported*", x[1].id} unless special %}
          {% SPEC_TYPES << {"*NonNull*", x[1].id} unless special %}
          {{x[1].id}} |
        {% end %}
      {% end %}

      {% if special %}
        NoReturn
      {% else %}
        {% SPEC_TYPES << {"*Supported*", "#{group.id}::Null"} %}
        {{group.id}}::Null
      {% end %}
  end

  macro define_not_null_for(type, group, name, register=true)
    {% ActiveRecord::SPEC_TYPES << {group, name} if register == true %}

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
ActiveRecord.define_not_null_for(:struct, Int, Int, register: false)
ActiveRecord.define_not_null_for(:struct, Int, Int8)
ActiveRecord.define_not_null_for(:struct, Int, UInt8)
ActiveRecord.define_not_null_for(:struct, Int, Int16)
ActiveRecord.define_not_null_for(:struct, Int, UInt16)
ActiveRecord.define_not_null_for(:struct, Int, Int32)
ActiveRecord.define_not_null_for(:struct, Int, UInt32)
ActiveRecord.define_not_null_for(:struct, Int, Int64)
ActiveRecord.define_not_null_for(:struct, Int, UInt64)

ActiveRecord.register_type :class, String, default: ""
ActiveRecord.define_not_null_for(:class, String, String)

ActiveRecord.register_type :struct, Time, default: Time.new(0), comparable: true
ActiveRecord.define_not_null_for(:struct, Time, Time)

ActiveRecord.register_type :struct, Bool, default: false
ActiveRecord.define_not_null_for(:struct, Bool, Bool)

module ActiveRecord
  alias_types Int
  alias_types String
  alias_types Time
  alias_types Bool

  alias_types "*Supported*", true, SupportedType
  alias_types "*NonNull*", true, NonNullType

  class NullCheckFailed < Exception; end
end
