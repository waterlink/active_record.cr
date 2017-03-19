require "./spec_helper"

class PersonWithPosts < ActiveRecord::Join
  one Person, id
  many Post, author_id
end

describe "joins" do
  it "allows to get one person with no posts" do
    # ARRANGE
    person = new_person.create

    # ACT
    actual = PersonWithPosts.get(person.id)

    # ASSERT
    actual.person.should eq(person)
  end
end
