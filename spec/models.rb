class Employee < ActiveRecord::Base
  include PeriodicRecords::Associations

  has_many :employee_assignments, inverse_of: :employee
  has_periodic :employee_assignments, as: :assignments
end

class EmployeeAssignment < ActiveRecord::Base
  include PeriodicRecords::Model

  belongs_to :employee

  def siblings
    self.class.where(employee_id: employee_id).where.not(id: id)
  end
end
