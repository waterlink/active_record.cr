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
    end

    module OneToMany(B, F)
      def connection
        B.pool.connection do |adapter|
          F.pool.connection do |foreign_adapter|
            yield adapter.with_joins({
              F.table_name_value => (criteria(@@primary) == criteria(@@foreign))
            }, foreign_adapter)
          end
        end
      end

      def build(record)
        new(record.base_record, record.foreign_records)
      end
    end

    class Record(B, F)
      getter base_record, foreign_records
      def initialize(@base_record : B, @foreign_records : F)
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
