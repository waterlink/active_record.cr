module ActiveRecord
  # Model::Fields represents collection of typed fields for model instance
  class Model::Fields
    # Generic(T, V) represents collection of fields of type T with
    # corresponding active record types V
    class Generic(T, V)
      getter fields

      def initialize
        @fields = {} of ::String => V
      end

      def set_field(name, value)
        if value.is_a?(T)
          fields[name] = value
        end
        value
      end
    end

    # Int is the collection of integer fields
    alias Int = Generic(IntTypes, IntTypes)

    # String is the collection of string fields
    alias String = Generic(::String, StringTypes)

    # TIme is the collection of datetime fields
    alias Time = Generic(::Time, TimeTypes)

    # Bool is the collection of boolean fields
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

    # [] is for accessing fields collection of specific type
    def [](its_type)
      typed_fields[its_type]
    end

    # to_h flattens typed collection to Hash(String, ActiveRecord::SupportedType)
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
