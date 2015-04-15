require "./spec_helper"

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

module ActiveRecord
  describe Model do

    describe ".new" do
      it "creates person" do
        new_person.should be_a(Person)
      end
    end

    describe "equality" do
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

  end
end
