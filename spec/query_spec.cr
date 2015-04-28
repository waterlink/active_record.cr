require "./spec_helper"
require "mocks"
require "../src/criteria"

module ActiveRecord
  create_double "Condition" do
    mock instance.==(other)
  end

  describe Query do
    describe "#same_query?" do
      condition_a = double("Condition")
      condition_b = double("Condition")

      it "is not the same query if other is not a Query" do
        Query.new(condition_a).same_query?(nil).should be_false
        Query.new(condition_a).same_query?({} of Symbol => String).should be_false
        Query.new(condition_a).same_query?(3).should be_false
        Query.new(condition_a).same_query?("hello world").should be_false
        Query.new(condition_a).same_query?(Object).should be_false
        Query.new(condition_a).same_query?(criteria("some")).should be_false
      end

      it "is the same query if other is a Query with the same condition" do
        allow(condition_a).to receive(instance.==(condition_b)).and_return(true)
        Query.new(condition_a).same_query?(Query.new(condition_b)).should be_true
      end

      it "is not the same query if other is a Query with different condition" do
        allow(condition_a).to receive(instance.==(condition_b)).and_return(false)
        Query.new(condition_a).same_query?(Query.new(condition_b)).should be_false
      end
    end
  end
end
