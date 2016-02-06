module ActiveRecord
  # Model::Fields represents collection of typed fields for model instance
  class Model::Fields
    # Generic(T) represents collection of fields of type T
    class Generic(T)
      getter fields

      def initialize
        @fields = {} of ::String => T
      end

      def set_field(name, value)
        if value.is_a?(T)
          fields[name] = value
        end
        value
      end
    end

    {% for group in TYPE_GROUPS %}
      alias {{group.id}} = Generic({{group.id}}Types)
    {% end %}

    private getter typed_fields

    def initialize
      @typed_fields = init_typed_fields
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

private macro init_typed_fields
  {
    {% for group in TYPE_GROUPS %}
      {{group.id.stringify}} => {{group.id}}.new,
    {% end %}
  }
end
