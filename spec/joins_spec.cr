require "./spec_helper"

class PersonWithPostsJoinQuery < ActiveRecord::NullAdapter::JoinQuery
  def call(base_record, foreign_record)
    return  base_record &&
            foreign_record &&
            base_record["id"] == foreign_record["author_id"]
  end
end

ActiveRecord::NullAdapter.register_join_query(
  "people.id = posts.author_id",
  PersonWithPostsJoinQuery.new
)

class PersonWithExampleJoinQuery < ActiveRecord::NullAdapter::JoinQuery
  def call(base_record, foreign_record)
    return  base_record &&
            foreign_record &&
            base_record["id"] == foreign_record["person_id"]
  end
end

ActiveRecord::NullAdapter.register_join_query(
  "people.id = example_models.person_id",
  PersonWithExampleJoinQuery.new
)

class PersonWithPosts < ActiveRecord::Join
  one Person, id
  many Post, author_id
end

class PersonWithExample < ActiveRecord::Join
  one Person, id
  one ExampleModel, person_id
end

describe "joins - one to many" do
  it "allows to get one person with no posts" do
    # ARRANGE
    person = new_person.create

    # ACT
    actual = PersonWithPosts.get(person.id)

    # ASSERT
    actual.person.should eq(person)
  end

  it "allows to get one person with one post" do
    # ARRANGE
    person = new_person.create
    post = Post.create({
      "title" => "hello",
      "content" => "world",
      "author_id" => person.id
    })

    # ACT
    actual = PersonWithPosts.get(person.id)

    # ASSERT
    actual.person.should eq(person)
    actual.posts.should eq([post])
  end

  it "allows to get one person with two posts" do
    # ARRANGE
    person = new_person.create
    post_a = Post.create({
      "title" => "post a",
      "content" => "hi",
      "author_id" => person.id
    })
    post_b = Post.create({
      "title" => "post b",
      "content" => "hi",
      "author_id" => person.id
    })

    # ACT
    actual = PersonWithPosts.get(person.id)

    # ASSERT
    actual.person.should eq(person)
    actual.posts.should eq([post_a, post_b])
  end

  it "allows to get one person with one post and without posts of other" do
    # ARRANGE
    person = new_person.create
    post_a = Post.create({
      "title" => "post a",
      "content" => "hi",
      "author_id" => person.id
    })

    other = new_person.create
    post_b = Post.create({
      "title" => "post b",
      "content" => "hi",
      "author_id" => other.id
    })

    # ACT
    actual = PersonWithPosts.get(person.id)

    # ASSERT
    actual.person.should eq(person)
    actual.posts.should eq([post_a])
  end
end

describe "joins - one to one" do
  it "fails with RecordNotFoundException when foreign record is not present" do
    # ARRANGE
    person = new_person.create

    # ACT & ASSERT
    expect_raises ActiveRecord::RecordNotFoundException do
      actual = PersonWithExample.get(person.id)
    end
  end

  it "allows to get one person with one foreign record" do
    # ARRANGE
    person = new_person.create
    example = ExampleModel.create({
      "name" => "hello",
      "person_id" => person.id
    })

    # ACT
    actual = PersonWithExample.get(person.id)

    # ASSERT
    actual.person.should eq(person)
    actual.example_model.should eq(example)
  end

  it "allows to get one person with one foreign record when there are multiple" do
    # ARRANGE
    person = new_person.create
    example_a = ExampleModel.create({
      "name" => "example a",
      "person_id" => person.id
    })
    example_b = ExampleModel.create({
      "name" => "example b",
      "person_id" => person.id
    })

    # ACT
    actual = PersonWithExample.get(person.id)

    # ASSERT
    actual.person.should eq(person)
    actual.example_model.should eq(example_a)
  end

  it "allows to get one person with one example and without example of other" do
    # ARRANGE
    person = new_person.create
    example_a = ExampleModel.create({
      "name" => "example a",
      "person_id" => person.id
    })

    other = new_person.create
    example_b = ExampleModel.create({
      "name" => "example b",
      "person_id" => other.id
    })

    # ACT
    actual = PersonWithExample.get(person.id)
    other_actual = PersonWithExample.get(other.id)

    # ASSERT
    actual.person.should eq(person)
    actual.example_model.should eq(example_a)

    other_actual.person.should eq(other)
    other_actual.example_model.should eq(example_b)
  end
end
