require "./spec_helper"

module ActiveRecord
  class MoreDependents < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("number_of_dependents") &&
        params.has_key?("1")
      actual = fields["number_of_dependents"] as Int
      expected = params["1"] as Int
      actual > expected
    end
  end

  NullAdapter.register_query("number_of_dependents > :1", MoreDependents.new)

  class LessDependents < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("number_of_dependents") &&
        params.has_key?("1")
      actual = fields["number_of_dependents"] as Int
      expected = params["1"] as Int
      actual < expected
    end
  end

  NullAdapter.register_query("number_of_dependents < :1", LessDependents.new)

  class LessAndMoreDependents < NullAdapter::Query
    def call(params, fields)
      return false unless fields.has_key?("number_of_dependents") &&
        params.has_key?("1") && params.has_key?("2")
      actual = fields["number_of_dependents"] as Int
      low = params["1"] as Int
      high = params["2"] as Int
      actual > low && actual < high
    end
  end

  NullAdapter.register_query("(number_of_dependents > :1) AND (number_of_dependents < :2)",
                             LessAndMoreDependents.new)
end

class Example; end

class Person < ActiveRecord::Model

  name Person
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

  null_object Null < Person do
    def to_s
      "No person"
    end
  end

end

class AnotherModel < ActiveRecord::Model

  name AnotherModel
  adapter null
  table_name something_else

  primary id :: Int
  field name :: String

end

class Post < ActiveRecord::Model

  name Post
  adapter null
  table_name posts

  primary id      :: Int
  field   title   :: String
  field   content :: String

  field_level :protected

  def self.latest
    index
  end

  def short_content
    content[0..16] + "..."
  end
end

class ExampleModel < ActiveRecord::Model

  name ExampleModel
  adapter fake

  primary  id    :: Int
  field    name  :: String
end

class AnotherExampleModel < ActiveRecord::Model

  name AnotherExampleModel
  adapter fake
  table_name some_models

  primary  id    :: Int
  field    name  :: String
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
        Person.find(person.id).should eq(person)

        example = AnotherModel.new.create
        example.id.should_not be_a(Int::Null)
        example.should_not eq(AnotherModel.new)
        AnotherModel.find(example.id).should eq(example)
      end

      it "can be used through .create" do
        person = Person.create({ "last_name" => "john" })
        person.id.should_not be_a(Int::Null)
        person.should_not eq(Person.new({ "last_name" => "john" }))
        person.should_not eq(Person.create({ "last_name" => "john" }))
        Person.find(person.id).should eq(person)

        ghost = Person.create
        ghost.id.should_not be_a(Int::Null)
        ghost.should_not eq(Person.new)
        ghost.should_not eq(Person.create)
        Person.find(ghost.id).should eq(ghost)
      end
    end

    describe ".find" do
      it "finds record properly" do
        person = new_person.create
        other_person = new_other_person.create

        Person.find(person.id).should eq(person)
        Person.find(other_person.id).should eq(other_person)
        Person.find(person.id).should_not eq(other_person)
        Person.find(other_person.id).should_not eq(person)
      end

      it "is of right class" do
        person = new_person.create
        Person.find(person.id).get_tax_exemption.should eq(0.17)
      end

      it "works correctly with encapsulated levels" do
        post = Post.create({ "title" => "My first post",
                             "content" => "Lots of content here" * 100 })

        Post.find(post.id).short_content.should eq("Lots of content h...")
      end
    end

    describe ".index" do
      it "finds all records" do
        p1 = new_person.create
        p2 = new_other_person.create
        p3 = new_other_person.create

        Person.index.should eq([p1, p2, p3])
      end

      it "works correctly with custom methods" do
        post = Post.create({ "title" => "My first post",
                             "content" => "Lots of content here" * 100 })

        Post.index.first.short_content.should eq("Lots of content h...")
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

    describe ".where(Query)" do
      it "finds multiple records by raw parametrized query" do
        p1 = new_person.create
        p2 = new_other_person.create
        p3 = new_other_person.create
        p4 = new_person.create
        p5 = new_person.create
        p6 = new_person.create
        p7 = new_other_person.create
        p8 = Person.create({ "last_name" => "maria", "number_of_dependents" => 2 })

        Person.where(criteria("number_of_dependents") > 1).should eq([p1, p4, p5, p6, p8])

        Person.where(criteria("number_of_dependents") < 3).should eq([p2, p3, p7, p8])

        Person.where((criteria("number_of_dependents") > 1).and(criteria("number_of_dependents") < 3))
          .should eq([p8])
      end
    end

    describe "#update" do
      it "does not change in data store when haven't been called yet" do
        person = new_person.create
        person.number_of_dependents = 4
        Person.find(person.id).should_not eq(person)
      end

      it "updates record in store" do
        person = new_person.create
        person_a = Person.find(person.id)
        person.number_of_dependents = 4
        person.update

        Person.find(person.id).should eq(person)
        person.should_not eq(person_a)
        Person.find(person.id).should_not eq(person_a)
      end
    end

    describe "#delete" do
      it "removes it from data store" do
        person = new_person.create
        person.delete
        Person.find(person.id).should_not eq(person)
        Person.find(person.id).should be_a(Person::Null)
        Person.find(person.id).to_s.should eq("No person")
      end
    end

    describe ".table_name" do
      it "equals to provided value" do
        AnotherExampleModel.create({ "name" => "hello world" })
        FakeAdapter.instance.table_name.should eq("some_models")
      end

      it "equals to plural form by default" do
        ExampleModel.create({ "name" => "hello world" })
        FakeAdapter.instance.table_name.should eq("example_models")
      end
    end
  end
end
