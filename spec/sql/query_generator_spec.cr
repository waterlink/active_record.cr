require "../spec_helper"
require "../../src/sql/*"

class UnknownExpression
end

def generate(query : ActiveRecord::SupportedType)
  ActiveRecord::Sql::QueryGenerator.new.generate(query).query
end

def generate(query : Query::Query)
  ActiveRecord::Sql::QueryGenerator.new.generate(query).query
end

module ActiveRecord
  module Sql
    describe QueryGenerator do
      describe "#generate" do
        example "returns Next for unknown expression" do
          QueryGenerator.new.generate(UnknownExpression.new)
                            .should be_a(::ActiveRecord::QueryGenerator::Next)
        end

        example "returns Response for known expression" do
          query = QueryGenerator.new.generate(criteria("person_id") == 5)

          query.should be_a(::ActiveRecord::QueryGenerator::GeneratedQuery)

          query.match(::ActiveRecord::QueryGenerator::GeneratedQuery) do |value|
            value.query.should be_a(Query)
          end
        end
      end

      describe "#_generate" do
        example "simple expressions" do
          generate(55).should eq(Query[":1", {"1" => 55}])
          generate("hello world").should eq(Query[":1", {"1" => "hello world"}])
        end

        example "==" do
          generate(criteria("person_id") == 59)
            .should eq(Query["person_id = :1", {"1" => 59}])

          generate(criteria("person_id") == "hello world")
            .should eq(Query["person_id = :1", {"1" => "hello world"}])

          generate(criteria("person_id") == criteria("owner_id"))
            .should eq(Query["person_id = owner_id"])
        end

        example "!=" do
          generate(criteria("person_id") != 59)
            .should eq(Query["person_id <> :1", {"1" => 59}])

          generate(criteria("person_id") != "hello world")
            .should eq(Query["person_id <> :1", {"1" => "hello world"}])

          generate(criteria("person_id") != criteria("owner_id"))
            .should eq(Query["person_id <> owner_id"])
        end

        example ">" do
          generate(criteria("number") > 30)
            .should eq(Query["number > :1", {"1" => 30}])
        end

        example ">=" do
          generate(criteria("number") >= 30)
            .should eq(Query["number >= :1", {"1" => 30}])
        end

        example "<" do
          generate(criteria("number") < 30)
            .should eq(Query["number < :1", {"1" => 30}])
        end

        example "<=" do
          generate(criteria("number") <= 30)
            .should eq(Query["number <= :1", {"1" => 30}])
        end

        example "or" do
          query = (criteria("number") < 29) |
                  (criteria("other_number") == 2)
                    .or(criteria("kind") == "none")

          expected_query = Query.new(
            "(number < :1) OR ((other_number = :2) OR (kind = :3))",
            {"1" => 29, "2" => 2, "3" => "none"},
          )

          generate(query).should eq(expected_query)

          query = ((criteria("number") < 29) |
                   (criteria("other_number") == 2))
            .or(criteria("kind") == "none")

          expected_query = Query.new(
            "((number < :1) OR (other_number = :2)) OR (kind = :3)",
            {"1" => 29, "2" => 2, "3" => "none"},
          )

          generate(query).should eq(expected_query)
        end

        example "and" do
          query = (criteria("number") < 29) &
                  (criteria("other_number") == 2)
                    .and(criteria("kind") == "none")

          expected_query = Query.new(
            "(number < :1) AND ((other_number = :2) AND (kind = :3))",
            {"1" => 29, "2" => 2, "3" => "none"},
          )

          generate(query).should eq(expected_query)
        end

        example "mixing and, or" do
          query = (criteria("number") < 29) &
                  (criteria("other_number") == 2)
                    .or(criteria("kind") == "none")

          expected_query = Query.new(
            "(number < :1) AND ((other_number = :2) OR (kind = :3))",
            {"1" => 29, "2" => 2, "3" => "none"},
          )

          generate(query).should eq(expected_query)
        end

        example "xor" do
          query = (criteria("number") < 29).xor(criteria("other_number") == 2)
          expected_query = Query["(number < :1) XOR (other_number = :2)",
            {"1" => 29, "2" => 2}]

          generate(query).should eq(expected_query)
        end

        example "not" do
          query = (criteria("number") < 35).not
          expected_query = Query["NOT (number < :1)", {"1" => 35}]
          generate(query).should eq(expected_query)

          query = ((criteria("number") < 35).and(criteria("other_person") == 1)).not
          expected_query = Query["NOT ((number < :1) AND (other_person = :2))",
            {"1" => 35, "2" => 1}]
          generate(query).should eq(expected_query)

          query = (criteria("number") < 35).not.and(criteria("other_person") == 1)
          expected_query = Query["(NOT (number < :1)) AND (other_person = :2)",
            {"1" => 35, "2" => 1}]
          generate(query).should eq(expected_query)

          query = (criteria("number") < 35).and((criteria("other_person") == 1).not)
          expected_query = Query["(number < :1) AND (NOT (other_person = :2))",
            {"1" => 35, "2" => 1}]
          generate(query).should eq(expected_query)
        end

        example "IS expressions" do
          [

            {criteria("bool").is_true, "(bool) IS TRUE", Query::EMPTY_PARAMS},
            {criteria("bool").is_not_true, "(bool) IS NOT TRUE", Query::EMPTY_PARAMS},
            {(criteria("bool") < 3).is_true, "(bool < :1) IS TRUE", {"1" => 3}},
            {(criteria("bool") < 3).is_not_true, "(bool < :1) IS NOT TRUE", {"1" => 3}},

            {criteria("bool").is_false, "(bool) IS FALSE", Query::EMPTY_PARAMS},
            {criteria("bool").is_not_false, "(bool) IS NOT FALSE", Query::EMPTY_PARAMS},
            {(criteria("bool") < 3).is_false, "(bool < :1) IS FALSE", {"1" => 3}},
            {(criteria("bool") < 3).is_not_false, "(bool < :1) IS NOT FALSE", {"1" => 3}},

            {criteria("something").is_unknown, "(something) IS UNKNOWN", Query::EMPTY_PARAMS},
            {criteria("something").is_not_unknown, "(something) IS NOT UNKNOWN", Query::EMPTY_PARAMS},
            {(criteria("something") < 3).is_unknown, "(something < :1) IS UNKNOWN", {"1" => 3}},
            {(criteria("something") < 3).is_not_unknown, "(something < :1) IS NOT UNKNOWN", {"1" => 3}},

            {criteria("something").is_null, "(something) IS NULL", Query::EMPTY_PARAMS},
            {criteria("something").is_not_null, "(something) IS NOT NULL", Query::EMPTY_PARAMS},
            {(criteria("something") < 3).is_null, "(something < :1) IS NULL", {"1" => 3}},
            {(criteria("something") < 3).is_not_null, "(something < :1) IS NOT NULL", {"1" => 3}},

          ].each do |example|
            query = example[0]
            expected_query = Query[example[1], example[2]]
            generate(query).should eq(expected_query)
          end
        end
      end
    end
  end
end
