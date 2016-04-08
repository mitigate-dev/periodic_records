# PeriodicRecords

[![Build Status](https://travis-ci.org/mak-it/periodic_records.svg?branch=master)](https://travis-ci.org/mak-it/periodic_records)

Support functions for ActiveRecord models with periodic entries.

* Supports periods where the smallest unit is a whole day
* Adjusts and splits overlapping records
* Preloads currently active records to avoid N+1 queries
* Easy querying within history - join returns 0..1 records (no grouping needed)
  `LEFT JOIN ... ON ... AND <date> BETWEEN start_at AND end_at`

For example you have employees table and assignments table that stores all the
employment history.

Employees:

id | name
---|------
1  | John

Employee assignments:

id | employee_id | start_at   | end_at     | job_title
---|-------------|------------|------------|----------
1  | 1           | 2014-01-01 | 9999-01-01 | Developer

Now John is promoted to "Senior Developer" and you create a new employee
assignment record and this gem will take care of adjusting and splitting
overlapping records. In this case it will adjust the `end_at` field for the
previous assignment.

id | employee_id | start_at   | end_at     | job_title
---|-------------|------------|------------|-----------------
1  | 1           | 2014-01-01 | 2018-05-04 | Developer
2  | 1           | 2018-05-05 | 9999-01-01 | Senior Developer


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'periodic_records'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install periodic_records
```

## Preparation

Ensure `start_at` and `end_at` date columns on the model that will have
periodic versions.
Include `PeriodicRecords::Model` and define `siblings` method:

```ruby
class EmployeeAssignment < ActiveRecord::Base
  include PeriodicRecords::Model

  belongs_to :employee

  def siblings
    self.class.where(employee_id: employee_id).where.not(id: id)
  end
end
```

Include `PeriodicRecords::Associations` in the model that has periodic
associations, and call `has_periodic`:

```ruby
class Employee < ActiveRecord::Base
  include PeriodicRecords::Associations

  has_many :employee_assignments, inverse_of: :employee
  has_periodic :employee_assignments, as: :assignments
end
```

## Usage

Look up the currently active record with `model.current_association`:

```ruby
employee.current_assignment
```

Look up records for specific date or period
with `within_date` and `within_interval`:

```ruby
employee.employee_assignments.within_date(Date.tomorrow)
```

```ruby
employee.employee_assignments.within_interval(Date.current.beginning_of_month...Date.current.end_of_month)
```

Look up records starting with specific date with `from_date`

```ruby
employee.employee_assignments.from_date(Date.tomorrow)
```

Preload currently active records, to avoid N+1 queries on `current_assignment`.

```ruby
employees = Employee.all
Employee.preload_current_assignments(employees)
employees.each do |employee|
  puts employee.current_assignment.to_s
end
```

## Database Constraints

To avoid inconsistent data in race conditions, you can add database constraint
that checks overlapping periods.

Postgres:

```ruby
class AddEmployeeAssignmentsOverlappingDatesConstraint < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"
    execute <<-SQL
      ALTER TABLE employee_assignments
      ADD CONSTRAINT employee_assignments_overlapping_dates
      EXCLUDE USING GIST(
        employee_id WITH =,
        TSRANGE(start_at, end_at) WITH &&
      )
    SQL
  end

  def down
    execute <<-SQL.squish
      ALTER TABLE employee_assignments
      DROP CONSTRAINT employee_assignments_overlapping_dates
    SQL
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release` to create a git tag for the version,
push git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/mak-it/periodic_records/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
