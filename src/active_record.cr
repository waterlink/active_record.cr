require "./active_record/*"

module ActiveRecord
  alias SupportedType = String|Int

  class Model
    macro adapter(value)
      @@adapter = {{value.stringify}}
    end

    macro table_name(value)
      @@table_name = {{value.stringify}}
    end

    macro primary(field_declaration)
      field {{field_declaration}}
    end

    macro field(field_declaration)
      def {{field_declaration.var}}=(value : {{field_declaration.type}})
        fields[{{field_declaration.var.stringify}}] = value
      end

      def {{field_declaration.var}}
        fields[{{field_declaration.var.stringify}}]
      end

      register_field({{field_declaration.var.stringify}})
    end

    def self.register_field(name)
      fields << name
    end

    def self.fields
      @@fields ||= [] of String
    end

    def initialize(hash)
      hash.each do |field, value|
        fields[field] = value
      end
    end

    def ==(other)
      return false unless other.is_a?(Model)
      self.fields == other.fields
    end

    protected def fields
      @fields ||= {} of String => SupportedType
    end
  end
end
