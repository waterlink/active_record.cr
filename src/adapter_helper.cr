module ActiveRecord
  module AdapterHelper
    class UnableToGenerate < ArgumentError
    end

    def query_generator(generator)
      query_generators << generator
      generator.used(self)
    end

    def query_generators
      (@@query_generators ||= [] of QueryGenerator).not_nil!
    end

    def generate_query(query)
      query_generators.each do |generator|
        generator.generate(query).match(QueryGenerator::GeneratedQuery) do |generated|
          return generated.query
        end
      end

      raise UnableToGenerate.new("#{self.inspect} is unable to generate query from #{query.inspect}")
    end
  end
end
