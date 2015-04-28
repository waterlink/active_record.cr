require "./spec_helper"

module ActiveRecord
  describe Criteria do
    describe "#==" do
      it "returns a Query object with Equal(receiver, argument)" do
        criteria("a_field").==("hello world")
          .should be_same_query(Query.new(Query::Equal.new(criteria("a_field"), "hello world")))

        criteria("a_field").==(criteria("another_field"))
          .should be_same_query(Query.new(Query::Equal.new(criteria("a_field"), criteria("another_field"))))

        criteria("a_field").==(criteria("another_field"))
          .should_not be_same_query(Query.new(Query::Equal.new(criteria("a_field"), criteria("a_field"))))
      end
    end

    describe "#same_query?" do
      it "is the same query if argument is the criteria with the same name" do
        criteria("a_field").same_query?(criteria("a_field")).should be_true
      end

      it "is not the same query if argument is the criteria with different name" do
        criteria("a_field").same_query?(criteria("another_field")).should be_false
      end

      it "is not the same query if argument is not a criteria" do
        criteria("a_field").same_query?("hello world").should be_false
        criteria("a_field").same_query?(35).should be_false
        criteria("a_field").same_query?(nil).should be_false
        criteria("a_field").same_query?(Object).should be_false
        criteria("a_field").same_query?(Query.new(nil)).should be_false
        criteria("a_field").same_query?({} of String => Int).should be_false
      end
    end
  end
end
