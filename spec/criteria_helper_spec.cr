require "./spec_helper"

module ActiveRecord
  class CriteriaHelperExample
    include CriteriaHelper
  end

  describe CriteriaHelper do
    obj = CriteriaHelperExample.new

    describe "#criteria" do
      it "creates an instance of criteria" do
        obj.criteria("number_of_dependents")
           .should be(Criteria.build("number_of_dependents"))
      end
    end
  end
end
