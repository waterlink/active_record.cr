module ActiveRecord
  class Model::Fields
    class Int
      getter fields

      def initialize
        @fields = {} of ::String => IntTypes
      end

      def set_field(name, value)
        if value.is_a?(::Int)
          fields[name] = value
        end
        value
      end
    end

    class String
      getter fields

      def initialize
        @fields = {} of ::String => ::String
      end

      def set_field(name, value)
        if value.is_a?(::String)
          fields[name] = value
        end
        value
      end
    end

    class Time
      getter fields

      def initialize
        @fields = {} of ::String => ::Time
      end

      def set_field(name, value)
        if value.is_a?(::Time)
          fields[name] = value
        end
        value
      end
    end

    private getter typed_fields

    def initialize
      @typed_fields = {
        "Int"    => Int.new,
        "String" => String.new,
        "Time"   => Time.new,
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
