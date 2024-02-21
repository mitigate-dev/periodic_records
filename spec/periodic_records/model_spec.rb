require 'spec_helper'

describe PeriodicRecords::Model do
  context "with start_at and end_at as `Date`" do
    let(:employee) { Employee.create }

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

      it "deletes overlapping record if it overlaps completely" do
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
  end

  context "with start_at and end_at as `Datetime`" do
    let(:employee) { TimeSensitiveEmployee.create }

    describe '#adjust_overlapping_records' do
      before do
        overlapping_record = employee.current_assignment
        overlapping_record.start_at = TimeSensitiveEmployeeAssignment::MIN
        overlapping_record.save!
      end

      it "splits overlapping record in two parts" do
        overlapping_record = employee.current_assignment
        new_record = new_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 1, 9, 20, 0),
          end_at:   Time.new(2014, 5, 6, 13, 45, 0)
        )
        expect(employee.employee_assignments.size).to eq 2
        new_record.save!
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3
        records = employee.employee_assignments.sort_by(&:start_at).to_a

        expect(records[0].start_at).to eq(TimeSensitiveEmployeeAssignment::MIN.to_time(:utc))
        expect(records[0].end_at).to   eq(Time.new(2014, 5, 1, 9, 19, 59))

        expect(records[1].start_at).to eq(Time.new(2014, 5, 1, 9, 20, 0))
        expect(records[1].end_at).to   eq(Time.new(2014, 5, 6, 13, 45, 0))

        expect(records[2].start_at).to eq(Time.new(2014, 5, 6, 13, 45, 1))
        expect(records[2].end_at).to   eq(TimeSensitiveEmployeeAssignment::MAX.to_time(:utc))
      end

      it "changes end_at for the overlapping record" do
        overlapping_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 1, 9, 0, 0),
          end_at:   Time.new(2014, 5, 6, 15, 30, 55)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3
        new_record = new_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 4, 11, 21, 0),
          end_at:   Time.new(2014, 5, 8, 17, 0, 0)
        )
        new_record.save!
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 4

        overlapping_record.reload
        expect(overlapping_record.start_at).to eq(Time.new(2014, 5, 1, 9, 0, 0))
        expect(overlapping_record.end_at).to   eq(Time.new(2014, 5, 4, 11, 20, 59))
      end

      it "changes start_at for the overlapping record" do
        overlapping_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 1, 10, 0, 0),
          end_at:   Time.new(2014, 5, 6, 10, 0, 0)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3
        new_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 4, 28, 8, 33, 25),
          end_at:   Time.new(2014, 5, 2, 11, 45, 56)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 4

        overlapping_record.reload
        expect(overlapping_record.start_at).to eq(Time.new(2014, 5, 2, 11, 45, 57))
        expect(overlapping_record.end_at).to   eq(Time.new(2014, 5, 6, 10, 0, 0))
      end

      it "changes start_at for the overlapping record (right at the beginning)" do
        overlapping_record = employee.current_assignment
        overlapping_record.start_at = Time.new(2014, 7, 21, 9, 0, 0)
        overlapping_record.end_at   = Time.new(2014, 7, 24, 18, 0, 0)
        overlapping_record.save!

        new_record = new_assignment(
          status:   'active',
          start_at: Time.new(2014, 7, 21, 9, 0, 0),
          end_at:   Time.new(2014, 7, 22, 12, 0, 0)
        )

        expect(employee.employee_assignments.size).to eq 2
        new_record.save!

        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 2

        records = employee.employee_assignments.sort_by(&:start_at).to_a

        expect(records[0].start_at).to eq(Time.new(2014, 7, 21, 9, 0, 0))
        expect(records[0].end_at).to   eq(Time.new(2014, 7, 22, 12, 0, 0))

        expect(records[1].start_at).to eq(Time.new(2014, 7, 22, 12, 0, 1))
        expect(records[1].end_at).to   eq(Time.new(2014, 7, 24, 18, 0, 0))
      end

      it "changes 2 overlapping records" do
        overlapping_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 1, 9, 0, 0),
          end_at:   Time.new(2014, 5, 6, 9, 0, 0)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3
        new_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 4, 28, 9, 0, 0),
          end_at:   Time.new(2014, 5, 2, 9, 0, 0)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 4

        records = employee.employee_assignments.sort_by(&:start_at).to_a

        expect(records[0].start_at).to eq(TimeSensitiveEmployeeAssignment::MIN.to_time(:utc))
        expect(records[0].end_at).to   eq(Time.new(2014, 4, 28, 8, 59, 59))

        expect(records[1].start_at).to eq(Time.new(2014, 4, 28, 9, 0, 0))
        expect(records[1].end_at).to   eq(Time.new(2014, 5, 2, 9, 0, 0))

        expect(records[2].start_at).to eq(Time.new(2014, 5, 2, 9, 0, 1))
        expect(records[2].end_at).to   eq(Time.new(2014, 5, 6, 9, 0, 0))

        expect(records[3].start_at).to eq(Time.new(2014, 5, 6, 9, 0, 1))
        expect(records[3].end_at).to   eq(TimeSensitiveEmployeeAssignment::MAX.to_time(:utc))
      end

      it "deletes overlapping record if it overlaps completely" do
        overlapping_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 2, 9, 0, 0),
          end_at:   Time.new(2014, 5, 4, 9, 0, 0)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3
        new_record = create_assignment(
          status:   'active',
          start_at: Time.new(2014, 5, 2, 8, 30, 0),
          end_at:   Time.new(2014, 5, 4, 11, 30, 0)
        )
        employee.employee_assignments.reload
        expect(employee.employee_assignments.size).to eq 3

        records = employee.employee_assignments.sort_by(&:start_at).to_a

        puts records[0].start_at.class.name
        expect(records[0].start_at).to eq(TimeSensitiveEmployeeAssignment::MIN.to_time(:utc))
        expect(records[0].end_at).to   eq(Time.new(2014, 5, 2, 8, 29, 59))

        expect(records[1].start_at).to eq(Time.new(2014, 5, 2, 8, 30, 0))
        expect(records[1].end_at).to   eq(Time.new(2014, 5, 4, 11, 30, 0))

        expect(records[2].start_at).to eq(Time.new(2014, 5, 4, 11, 30, 1))
        expect(records[2].end_at).to   eq(TimeSensitiveEmployeeAssignment::MAX.to_time(:utc))
      end
    end
  end
end
