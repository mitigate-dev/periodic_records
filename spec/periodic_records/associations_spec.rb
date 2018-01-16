require 'spec_helper'

describe PeriodicRecords::Model do
  let(:employee) { Employee.create }

  describe ".preload_current_assignments" do
    it "preloads current assignments" do
      create_assignment(status: 'active')
      employees = Employee.all
      Employee.preload_current_assignments(employees)
      EmployeeAssignment.delete_all
      employees.each do |employee|
        expect(employee.current_assignment).to be_present
      end
    end
  end
end
