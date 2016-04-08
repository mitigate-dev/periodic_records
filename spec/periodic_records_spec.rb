require 'spec_helper'

describe PeriodicRecords do
  subject(:employee) { Employee.create }

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

  describe '#adjust_overlapping_records' do
    before do
      overlapping_record = employee.current_assignment
      overlapping_record.start_at = EmployeeAssignment::MIN
      overlapping_record.save!
    end

    it "splits overlapping record in two parts" do
      overlapping_record = employee.current_assignment
      new_record = new_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 1),
        end_at:   Date.new(2014, 5, 6)
      )
      expect(employee.employee_assignments.size).to eq 2
      new_record.save!
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3
      records = employee.employee_assignments.sort_by(&:start_at).to_a

      expect(records[0].start_at).to eq(EmployeeAssignment::MIN)
      expect(records[0].end_at).to   eq(Date.new(2014, 4, 30))

      expect(records[1].start_at).to eq(Date.new(2014, 5, 1))
      expect(records[1].end_at).to   eq(Date.new(2014, 5, 6))

      expect(records[2].start_at).to eq(Date.new(2014, 5, 7))
      expect(records[2].end_at).to   eq(EmployeeAssignment::MAX)
    end

    it "changes end_at for the overlapping record" do
      overlapping_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 1),
        end_at:   Date.new(2014, 5, 6)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3
      new_record = new_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 4),
        end_at:   Date.new(2014, 5, 8)
      )
      new_record.save!
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 4

      overlapping_record.reload
      expect(overlapping_record.start_at).to eq(Date.new(2014, 5, 1))
      expect(overlapping_record.end_at).to   eq(Date.new(2014, 5, 3))
    end

    it "changes start_at for the overlapping record" do
      overlapping_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 1),
        end_at:   Date.new(2014, 5, 6)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3
      new_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 4, 28),
        end_at:   Date.new(2014, 5, 2)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 4

      overlapping_record.reload
      expect(overlapping_record.start_at).to eq(Date.new(2014, 5, 3))
      expect(overlapping_record.end_at).to   eq(Date.new(2014, 5, 6))
    end

    it "changes start_at for the overlapping record (right at the beginning)" do
      overlapping_record = employee.current_assignment
      overlapping_record.start_at = Date.new(2014, 7, 21)
      overlapping_record.end_at   = Date.new(2014, 7, 24)
      overlapping_record.save!

      new_record = new_assignment(
        status:   'active',
        start_at: Date.new(2014, 7, 21),
        end_at:   Date.new(2014, 7, 22)
      )

      expect(employee.employee_assignments.size).to eq 2
      new_record.save!

      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 2

      records = employee.employee_assignments.sort_by(&:start_at).to_a

      expect(records[0].start_at).to eq(Date.new(2014, 7, 21))
      expect(records[0].end_at).to   eq(Date.new(2014, 7, 22))

      expect(records[1].start_at).to eq(Date.new(2014, 7, 23))
      expect(records[1].end_at).to   eq(Date.new(2014, 7, 24))
    end

    it "changes 2 overlapping records" do
      overlapping_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 1),
        end_at:   Date.new(2014, 5, 6)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3
      new_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 4, 28),
        end_at:   Date.new(2014, 5, 2)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 4

      records = employee.employee_assignments.sort_by(&:start_at).to_a

      expect(records[0].start_at).to eq(EmployeeAssignment::MIN)
      expect(records[0].end_at).to   eq(Date.new(2014, 4, 27))

      expect(records[1].start_at).to eq(Date.new(2014, 4, 28))
      expect(records[1].end_at).to   eq(Date.new(2014, 5, 2))

      expect(records[2].start_at).to eq(Date.new(2014, 5, 3))
      expect(records[2].end_at).to   eq(Date.new(2014, 5, 6))

      expect(records[3].start_at).to eq(Date.new(2014, 5, 7))
      expect(records[3].end_at).to   eq(EmployeeAssignment::MAX)
    end

    it "deletes overlapping record if it overlaps completly" do
      overlapping_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 2),
        end_at:   Date.new(2014, 5, 4)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3
      new_record = create_assignment(
        status:   'active',
        start_at: Date.new(2014, 5, 1),
        end_at:   Date.new(2014, 5, 4)
      )
      employee.employee_assignments.reload
      expect(employee.employee_assignments.size).to eq 3

      records = employee.employee_assignments.sort_by(&:start_at).to_a

      expect(records[0].start_at).to eq(EmployeeAssignment::MIN)
      expect(records[0].end_at).to   eq(Date.new(2014, 4, 30))

      expect(records[1].start_at).to eq(Date.new(2014, 5, 1))
      expect(records[1].end_at).to   eq(Date.new(2014, 5, 4))

      expect(records[2].start_at).to eq(Date.new(2014, 5, 5))
      expect(records[2].end_at).to   eq(EmployeeAssignment::MAX)
    end
  end

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
end
