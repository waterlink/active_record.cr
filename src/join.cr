module ActiveRecord
  class Join
    @@primary = ""
    @@foreign = ""

    macro one(base_model, primary)
      include OneTo({{base_model.id}})
      @@primary = "#{ {{base_model}}.table_name_value }.{{primary.id}}"

      getter {{base_model.stringify.underscore.id}} : {{base_model.id}}

      def initialize(base_record)
        @{{base_model.stringify.underscore.id}} = {{base_model.id}}.build(base_record)
      end
    end

    module OneTo(B)
      macro many(foreign_model, foreign)
        extend OneToMany(B, {{foreign_model.id}})
        @@foreign = "#{ {{foreign_model}}.table_name_value }.{{foreign.id}}"

        getter {{foreign_model.stringify.underscore.id}}s
        @{{foreign_model.stringify.underscore.id}}s = [] of {{foreign_model.id}}

        def initialize(base_record, foreign_records)
          initialize(base_record)
          @{{foreign_model.stringify.underscore.id}}s = foreign_records.map do |record|
            {{foreign_model.id}}.build(record)
          end
        end
      end

      macro one(foreign_model, foreign)
        extend OneToOne(B, {{foreign_model.id}})
        @@foreign = "#{ {{foreign_model}}.table_name_value }.{{foreign.id}}"

        getter! {{foreign_model.stringify.underscore.id}}
        @{{foreign_model.stringify.underscore.id}} : {{foreign_model.id}}?

        def initialize(base_record, foreign_record)
          initialize(base_record)
          @{{foreign_model.stringify.underscore.id}} = {{foreign_model.id}}.build(foreign_record)
        end
      end
    end

    module OneToMany(B, F)
      JOIN_KIND = "one-to-many"

      def connection
        B.pool.connection do |adapter|
          F.pool.connection do |foreign_adapter|
            yield adapter.with_joins(JOIN_KIND, {
              F.table_name_value => (criteria(@@primary) == criteria(@@foreign))
            }, foreign_adapter)
          end
        end
      end

      def build(record : Nil)
        raise RecordNotFoundException.new("Record not found with given id.")
      end

      def build(record : Record(Hash(String, SupportedType)?, Array(Hash(String, SupportedType))))
        new(record.base_record, record.foreign)
      end

      def build(record : Record(Hash(String, SupportedType)?, Hash(String, SupportedType)))
        raise "unexpected one-to-one record response from adapter (expected one-to-many)"
      end
    end

    module OneToOne(B, F)
      JOIN_KIND = "one-to-one"

      def connection
        B.pool.connection do |adapter|
          F.pool.connection do |foreign_adapter|
            yield adapter.with_joins(JOIN_KIND, {
              F.table_name_value => (criteria(@@primary) == criteria(@@foreign))
            }, foreign_adapter)
          end
        end
      end

      def build(record : Nil)
        raise RecordNotFoundException.new("Record not found with given id.")
      end

      def build(record : Record(Hash(String, SupportedType)?, Array(Hash(String, SupportedType))))
        raise "unexpected one-to-many record response from adapter (expected one-to-one)"
      end

      def build(record : Record(Hash(String, SupportedType)?, Hash(String, SupportedType)))
        new(record.base_record, record.foreign)
      end
    end

    class Record(B, F)
      getter base_record, foreign
      def initialize(@base_record : B, @foreign : F)
      end
    end

    def self.connection(&blk)
      raise "not implemented"
    end

    def self.get(primary_key)
      connection do |adapter|
        record = adapter.get(primary_key)
        build(record).as(self)
      end
    end
  end
end
