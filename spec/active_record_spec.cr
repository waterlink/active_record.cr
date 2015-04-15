require "./spec_helper"

module ActiveRecord
  class MoreDependents < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("number_of_dependents") &&
        params.has_key?("number_of_dependents")
      actual = fields["number_of_dependents"] as Int
      expected = params["number_of_dependents"] as Int
      actual > expected
    end
  end

  NullAdapter.register_query("number_of_dependents > :number_of_dependents", MoreDependents.new)

  class LessDependents < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("number_of_dependents") &&
        params.has_key?("number_of_dependents")
      actual = fields["number_of_dependents"] as Int
      expected = params["number_of_dependents"] as Int
      actual < expected
    end
  end

  NullAdapter.register_query("number_of_dependents < :number_of_dependents", LessDependents.new)
end

class Example; end

class Person < ActiveRecord::Model

  adapter null
  table_name people

  primary id :: Int
  field last_name :: String
  field first_name :: String
  field number_of_dependents :: Int

  def get_tax_exemption
    return 0.0 if number_of_dependents < 2
    0.17
  end

end

class AnotherModel < ActiveRecord::Model

  adapter null
  table_name something_else

  primary id :: Int
  field name :: String

end

def new_person
  Person.new({ "first_name"           => "john",
               "last_name"            => "smith",
               "number_of_dependents" => 3 })
end

def new_other_person
  Person.new({ "first_name"           => "james",
               "last_name"            => "blake",
               "number_of_dependents" => 1 })
end

def new_ghost_person
  Person.new
end

module ActiveRecord
  describe Model do

    describe ".new" do
      it "creates person" do
        new_person.should be_a(Person)
      end

      it "doesn't have id" do
        new_person.id.should be_a(Int::Null)
      end

      it "doesn't have any else field" do
        new_ghost_person.last_name.should be_a(String::Null)
      end

      it "doesn't care about non-defined fields" do
        person = Person.new({ "last_name" => "John", "height" => 35 })
        person.should eq(Person.new({ "last_name" => "John" }))
      end
    end

    describe ".fields" do
      it "returns fields defined on model" do
        Person.fields.should eq(["id", "last_name", "first_name", "number_of_dependents"])
        AnotherModel.fields.should eq(["id", "name"])
      end
    end

    describe "#==" do
      it "is equal object to object with the same fields" do
        new_person.should eq(new_person)
      end

      it "is not equal to object with the different fields" do
        new_other_person.should_not eq(new_person)
      end

      it "is not equal to non-person objects" do
        new_person.should_not eq(nil)
        new_person.should_not eq(Object)
        new_person.should_not eq(55)
        new_person.should_not eq(Example.new)
      end
    end

    describe "#<field>=" do
      it "assigns field" do
        person = new_person
        person.id = 55
        person.id.should eq(55)
      end
    end

    describe "#create" do
      it "persists new record to database" do
        person = new_person.create
        person.id.should_not be_a(Int::Null)
        person.should_not eq(new_person)
        person.should_not eq(new_person.create)
        Person.read(person.id).should eq(person)

        example = AnotherModel.new.create
        example.id.should_not be_a(Int::Null)
        example.should_not eq(AnotherModel.new)
        AnotherModel.read(example.id).should eq(example)
      end

      it "can be used trhough .create" do
        person = Person.create({ "last_name" => "john" })
        person.id.should_not be_a(Int::Null)
        person.should_not eq(Person.new({ "last_name" => "john" }))
        person.should_not eq(Person.create({ "last_name" => "john" }))
        Person.read(person.id).should eq(person)

        ghost = Person.create
        ghost.id.should_not be_a(Int::Null)
        ghost.should_not eq(Person.new)
        ghost.should_not eq(Person.create)
        Person.read(ghost.id).should eq(ghost)
      end
    end

    describe ".read" do
      it "finds record properly" do
        person = new_person.create
        other_person = new_other_person.create

        Person.read(person.id).should eq(person)
        Person.read(other_person.id).should eq(other_person)
        Person.read(person.id).should_not eq(other_person)
        Person.read(other_person.id).should_not eq(person)
      end
    end

    describe ".where(query_hash)" do
      it "finds multiple records" do
        p1 = new_person.create
        p2 = new_other_person.create
        p3 = new_other_person.create
        p4 = new_person.create
        p5 = new_person.create
        p6 = new_person.create
        p7 = new_other_person.create

        Person.where({ "number_of_dependents" => 0 }).should eq([] of Person)
        Person.where({ "first_name" => "john" }).should eq([p1, p4, p5, p6])
        Person.where({ "number_of_dependents" => 1 }).should eq([p2, p3, p7])
        Person.where({ "first_name" => "john",
                       "number_of_dependents" => 1 }).should eq([] of Person)
        Person.where({ "first_name" => "john",
                       "number_of_dependents" => 3 }).should eq([p1, p4, p5, p6])
        Person.where({ "number_of_dependents" => 3 }).should eq([p1, p4, p5, p6])
      end
    end

    describe ".where(query, params)" do
      it "finds multiple records by raw parametrized query" do
        p1 = new_person.create
        p2 = new_other_person.create
        p3 = new_other_person.create
        p4 = new_person.create
        p5 = new_person.create
        p6 = new_person.create
        p7 = new_other_person.create
        p8 = Person.create({ "last_name" => "maria", "number_of_dependents" => 2 })

        Person.where("number_of_dependents > :number_of_dependents",
                     { "number_of_dependents" => 1 }).should eq([p1, p4, p5, p6, p8])

        Person.where("number_of_dependents < :number_of_dependents",
                     { "number_of_dependents" => 3 }).should eq([p2, p3, p7, p8])
      end
    end

  end
end
