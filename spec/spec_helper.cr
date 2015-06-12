require "spec"
require "mocks"
require "../src/active_record"
require "../src/null_adapter"
require "../src/criteria_helper"
require "./fake_adapter"

def _specs_reset
  ActiveRecord::NullAdapter.reset
  FakeAdapter._reset
end

Spec.before_each do
  _specs_reset
end

Spec.after_each do
  _specs_reset
end

class SameQueryExpectation(T)
  def initialize(@expected : T)
  end

  def match(@actual)
    ActiveRecord::QueryObject.same_query?(@expected, @actual)
  end

  def failure_message
    "expected: #{@expected.inspect}\n     got: #{@actual.inspect}"
  end

  def negative_failure_message
    "expected: value != #{@expected.inspect}\n     got: #{@actual.inspect}"
  end
end

def be_same_query(expected)
  SameQueryExpectation.new(expected)
end

include ActiveRecord::CriteriaHelper

def example(description, file = __FILE__, line = __LINE__, &block)
  it(description, file, line, &block)
end
