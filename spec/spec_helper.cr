require "spec"
require "../src/active_record"
require "../src/null_adapter"
require "../src/criteria_helper"

# Use this after next release of Crystal
#Spec.before_each do
#  ActiveRecord::NullAdapter.reset
#end
#
#Spec.after_each do
#  ActiveRecord::NullAdapter.reset
#end

# Now use this:
def it(description, file = __FILE__, line = __LINE__, &block)
  ActiveRecord::NullAdapter.reset
  previous_def(description, file, line, &block)
  ActiveRecord::NullAdapter.reset
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
