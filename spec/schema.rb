ActiveRecord::Schema.define do
  self.verbose = false

  create_table :employees, force: true do |t|
  end

  create_table :employee_assignments, force: true do |t|
    t.integer :employee_id
    t.date :start_at
    t.date :end_at
    t.string :status
  end
end
