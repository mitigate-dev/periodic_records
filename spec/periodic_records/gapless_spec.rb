require 'spec_helper'

describe PeriodicRecords::Gapless do
  let(:employee) { GaplessEmployee.create }
  let!(:assignments) do
    [
      create_assignment(GaplessEmployeeAssignment::MIN, Date.new(2018, 1, 15)),
      create_assignment(Date.new(2018, 1, 16), Date.new(2018, 2, 15)),
      create_assignment(Date.new(2018, 2, 16), GaplessEmployeeAssignment::MAX)
    ]
  end

  def create_assignment(start_at, end_at)
    employee.employee_assignments.create!(
      status: 'active',
      start_at: start_at,
      end_at: end_at
    )
  end

  describe '#valid?' do
    it "is not valid to change start_at if there is no previous record" do
      assignments[0].start_at = Date.current
      assignments[0].valid?
      expect(assignments[0].errors[:start_at]).to be_present
    end

    it "is not valid to change end_at if there is no next record" do
      assignments[2].end_at = Date.current
      assignments[2].valid?
      expect(assignments[2].errors[:end_at]).to be_present
    end
  end

  describe '#destroy' do
    context 'at the beginning' do
      it "does not destroy" do
        expect(assignments[0].destroy).to be(false)
        expect(GaplessEmployeeAssignment.exists?(assignments[0].id)).to eq(true)
      end
    end

    context 'in the middle' do
      it "destroys" do
        expect(assignments[1].destroy).to be(assignments[1])
        expect(GaplessEmployeeAssignment.exists?(assignments[1].id)).to eq(false)
      end

      it "adjusts end date for previous record" do
        assignments[1].destroy
        assignments[0].reload
        expect(assignments[0].end_at).to eq(Date.new(2018, 2, 15))
      end
    end

    context 'at the end' do
      it "does not destroy" do
        expect(assignments[2].destroy).to be(false)
        expect(GaplessEmployeeAssignment.exists?(assignments[2].id)).to eq(true)
      end
    end
  end

  describe '#save' do
    it "updating start_at changes end_at for the previous record" do
      assignments[1].start_at = Date.new(2018, 1, 20)
      assignments[1].save!
      assignments[0].reload
      expect(assignments[0].start_at).to eq(GaplessEmployeeAssignment::MIN)
      expect(assignments[0].end_at).to eq(Date.new(2018, 1, 19))
    end

    it "updating end_at changes start_at for the next record" do
      assignments[1].end_at = Date.new(2018, 2, 10)
      assignments[1].save!
      assignments[2].reload
      expect(assignments[2].start_at).to eq(Date.new(2018, 2, 11))
      expect(assignments[2].end_at).to eq(GaplessEmployeeAssignment::MAX)
    end
  end
end
