require "./criteria"
require "./query"

module ActiveRecord
  module CriteriaHelper
    def criteria(name)
      Criteria.build(name)
    end
  end
end
