require "./spec_helper"

module StuffGenerator
  def self.an_int
    37 as ActiveRecord::SupportedType
  end

  def self.an_int_null
    Int::Null.new as ActiveRecord::SupportedType
  end

  def self.a_string
    "hello world" as ActiveRecord::SupportedType
  end

  def self.a_string_null
    String::Null.new as ActiveRecord::SupportedType
  end
end

module ActiveRecord
  describe "supported types" do
    describe "Int" do
      it "is not null" do
        subject = StuffGenerator.an_int
        typeof(subject).should_not eq Int32
        typeof(subject).should eq SupportedType
        subject.null?.should eq false
        subject.not_null!.should eq subject
        typeof(subject.not_null!).should eq NonNullType
      end

      it "is null" do
        subject = StuffGenerator.an_int_null
        typeof(subject).should eq SupportedType
        typeof(subject).should_not eq Int32
        subject.null?.should eq true
        typeof(subject.not_null!).should eq NonNullType

        expect_raises(NullCheckFailed, /Int::Null/) do
          subject.not_null!
        end
      end
    end

    describe "String" do
      it "is not null" do
        subject = StuffGenerator.a_string
        typeof(subject).should_not eq String
        typeof(subject).should eq SupportedType
        subject.null?.should eq false
        subject.not_null!.should eq subject
        typeof(subject.not_null!).should eq NonNullType
      end

      it "is null" do
        subject = StuffGenerator.a_string_null
        typeof(subject).should eq SupportedType
        typeof(subject).should_not eq String
        subject.null?.should eq true
        typeof(subject.not_null!).should eq NonNullType

        expect_raises(NullCheckFailed, /String::Null/) do
          subject.not_null!
        end
      end
    end
  end
end
