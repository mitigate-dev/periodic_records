$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'active_support/all'

require 'periodic_records'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

load File.dirname(__FILE__) + '/schema.rb'
require File.dirname(__FILE__) + '/models.rb'


def new_assignment(attributes)
  employee.employee_assignments.new(
    employee.current_assignment.attributes.
      except("id", "start_at", "end_at").
      merge(attributes)
  )
end

def create_assignment(attributes)
  assignment = new_assignment(attributes)
  assignment.save!
  assignment
end
