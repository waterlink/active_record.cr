require "./spec_helper"

class Person < ActiveRecord::Model

  adapter null
  table_name people

  primary id : Int
  field last_name : String
  field first_name : String
  field number_of_dependents : Int

  def get_tax_exemption
    return 0.0 if number_of_dependents < 2
    0.17
  end

end

module ActiveRecord
  describe Model do

  end
end
