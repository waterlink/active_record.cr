module ActiveRecord
  module AdapterHelper
    def query_generator(generator)
      query_generator << generator
      generator.used(self)
    end

    def query_generator
      (@@query_generator ||= [] of QueryGenerator).not_nil!
    end
  end
end
