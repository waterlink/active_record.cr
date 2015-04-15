require "spec"
require "../src/active_record"
require "../src/null_adapter"

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
