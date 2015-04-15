require "./adapter"

module ActiveRecord
  module Registry
    extend self

    def register_adapter(name, adapter)
      adapters[name] = adapter
    end

    def adapter(name)
      adapters[name]
    end

    def adapters
      @@adapters ||= {} of String => Adapter.class
    end
  end
end
