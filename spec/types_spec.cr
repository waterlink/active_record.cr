require "./spec_helper"

module StuffGenerator
  def self.an_int
    37.as(ActiveRecord::SupportedType)
  end

  def self.an_int_null
    Int::Null.new.as(ActiveRecord::SupportedType)
  end

  def self.a_string
    "hello world".as(ActiveRecord::SupportedType)
  end

  def self.a_string_null
    String::Null.new.as(ActiveRecord::SupportedType)
  end
end

macro test_non_null(ty, value, other_value, name="_", check_op="")
context "when {{ty}} is not null" do
  subject = {{value}}.as(SupportedType)

  it "has correct type" do
    typeof(subject).should_not eq {{ty}}
    typeof(subject).should eq SupportedType
  end

  it "is not null" do
    subject.null?.should eq false
  end

  it "is possible to unwrap" do
    subject.not_null!.should eq subject
    subject.not_null!.should be_a({{ty}})
    typeof(subject.not_null!).should eq NonNullType
  end

  it "has valid to_s implementation" do
    subject.to_s.should eq({{value}}.to_s)
  end

  it "forwards calls to original value" do
    {{name.id}} = subject.as({{ty}})
    ({{check_op.id}}).should eq(true)
  end

  it "implements correct == method" do
    subject.should eq({{value}})
    subject.should_not eq({{other_value}})
    subject.should_not eq({{ty}}::Null.new)
  end
end
end

macro test_null(ty, zero, other_value, name="_", check_op="true")
context "when {{ty}} is null" do
  subject = {{ty}}::Null.new.as(SupportedType)

  it "has correct type" do
    typeof(subject).should_not eq {{ty}}
    typeof(subject).should eq SupportedType
  end

  it "is null" do
    subject.null?.should eq true
  end

  it "is impossible to unwrap" do
    typeof(subject.not_null!).should eq NonNullType
    expect_raises(NullCheckFailed, /{{ty}}::Null/) do
      subject.not_null!
    end
  end

  it "has valid to_s implementation" do
    subject.to_s.should eq("")
  end

  it "forwards calls to zero-like value" do
    {{name.id}} = subject.as({{ty}}::Null)
    ({{check_op.id}}).should eq(true)
  end

  it "implements correct == method" do
    subject.should eq({{zero}})
    subject.should_not eq({{other_value}})
    subject.should eq({{ty}}::Null.new)
  end
end
end

macro test_comparable(ty, spec_ty, value, zero)
it "implements correct Comparable" do
  subject = {{value}}.as(SupportedType)
  null = {{ty}}::Null.new.as(SupportedType)

  (subject.as({{spec_ty}}) <=> {{zero}}).should eq({{value}} <=> {{zero}})
  (null.as({{ty}}::Null) <=> {{value}}).should eq({{zero}} <=> {{value}})
end
end

module ActiveRecord
  describe "supported types" do
    describe Int do
      test_non_null Int8, 37_i8, 0, x, x + 5 == 42
      test_non_null Int16, 37_i16, 0, x, x + 5 == 42
      test_non_null Int32, 37_i32, 0, x, x + 5 == 42
      test_non_null Int64, 37_i64, 0, x, x + 5 == 42

      test_non_null UInt8, 37_u8, 0, x, x + 5 == 42
      test_non_null UInt16, 37_u16, 0, x, x + 5 == 42
      test_non_null UInt32, 37_u32, 0, x, x + 5 == 42
      test_non_null UInt64, 37_u64, 0, x, x + 5 == 42

      test_null Int, 0, 37, x, x + 5 == 5

      test_comparable Int, Int32, 37, 0
    end

    describe String do
      test_non_null String, "hello world", "", s, s + "!" == "hello world!"
      test_null String, "", "some string", s, s + "stuff" == "stuff"
    end

    describe Time do
      value = Time.new(2016, 2, 4, 17, 33, 29)
      zero = Time.new(0)

      test_non_null Time, value, zero, t,
        t + 2.hours == Time.new(2016, 2, 4, 19, 33, 29)

      test_null Time, zero, value, t, t + 1.day == zero + 1.day

      test_comparable Time, Time, value, zero
    end

    describe Bool do
      test_non_null Bool, true, false, x, !x == false
      test_null Bool, false, true
    end

    describe Float do
      test_non_null Float32, 2.5_f32, 0.0, x, x + 5 == 7.5
      test_non_null Float64, 2.5_f64, 0.0, x, x + 5 == 7.5

      test_null Float, 0.0, 2.5_f32, x, x + 5 == 5.0

      test_comparable Float, Float32, 2.5_f32, 0
    end
  end
end
