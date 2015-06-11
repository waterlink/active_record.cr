module ActiveRecord
  module Support
    extend self

    def snakecase(name)
      first = true

      String.build(name.bytesize * 2) do |str|
        name.each_char do |chr|
          if first
            first = false
          elsif ('A'..'Z').includes?(chr)
            str << '_'
          end
          str << chr.downcase
        end
      end
    end

    def plural(name)
      snakecase(name) + 's'
    end
  end
end
