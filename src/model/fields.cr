module ActiveRecord
  class Model::Fields
    class Generic(T, V)
      getter fields

      def initialize
        @fields = {} of ::String => V
      end

      def update_field(name, value)
        if value.is_a?(T)
          fields[name] = value
        end
        value
      end
    end

    alias Int = Generic(IntTypes, IntTypes)
    alias String = Generic(::String, StringTypes)
    alias Time = Generic(::Time, TimeTypes)
    alias Bool = Generic(::Bool, BoolTypes)

    private getter typed_fields

    def initialize
      @typed_fields = {
        "Int"    => Int.new,
        "String" => String.new,
        "Time"   => Time.new,
        "Bool"   => Bool.new,
      }
    end

    def [](its_type)
      typed_fields[its_type]
    end

    def to_h
      hash = {} of ::String => SupportedType

      typed_fields.each do |its_type, typed_fields|
        typed_fields.fields.each do |name, value|
          hash[name] = value
        end
      end

      hash
    end
  end
end
