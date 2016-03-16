require "./spec_helper"

module ActiveRecord
  class SameName < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("name")
      return false unless params.has_key?("1")

      actual = fields["name"] as String
      expected = params["1"] as String

      actual == expected
    end
  end

  NullAdapter.register_query(
    "name = :1",
    SameName.new,
  )

  class SameOtherModelId < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("other_model_id")
      return false unless params.has_key?("1")

      actual = fields["other_model_id"] as Int
      expected = params["1"] as Int

      actual == expected
    end
  end

  NullAdapter.register_query(
    "other_model_id = :1",
    SameOtherModelId.new,
  )
end

class AModel < ActiveRecord::Model
  adapter null
  table_name a_models

  primary id : Int
  field name : String
  field other_model_id : Int

  def self.with_name(name)
    where(criteria("name") == name)
  end

  def with_me
    AModel.where(criteria("other_model_id") == id)
  end
end

module ActiveRecord
  describe CriteriaHelper do
    it "is usable in model without including/extending" do
      model_a = AModel.create({"name" => "person"})
      model_b = AModel.create({"name"           => "account",
        "other_model_id" => model_a.id})
      model_c = AModel.create({"name" => "subject"})
      model_d = AModel.create({"name"           => "subscription",
        "other_model_id" => model_a.id})

      AModel.with_name("account").should eq([model_b])
      model_a.with_me.should eq([model_b, model_d])
    end
  end

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
        criteria("a_field").same_query?({} of String => Int32).should be_false
      end
    end
  end
end
