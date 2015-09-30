# PeriodicRecords

Support functions for ActiveRecord models with periodic entries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'periodic_records'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install periodic_records

## Preparation

Ensure `start_at` and `end_at` date columns on the model that will have periodic versions. Include `PeriodicRecords::Model`, setup callbacks and define `siblings` method:

```ruby
class EmployeeAssignment < ActiveRecord::Base
  include PeriodicRecords::Model

  belongs_to :employee

  def siblings
    self.class.where(employee_id: employee_id).where.not(id: id)
  end
end
```

Include `PeriodicRecords::Associations` in the model that has periodic associations, and call `has_periodic`:

```ruby
class Employee < ActiveRecord::Base
  include PeriodicRecords::Associations

  has_many :employee_assignments, inverse_of: :employee
  has_periodic :employee_assignments, as: :assignments
end
```

## Usage

Look up the currently active record with `model.current_association` or `model.association.current`:

```ruby
employee.current_assignment
```

```ruby
employee.employee_assignments.current
```

Look up records for specific date or period with `within_date` and `within_period`:

```ruby
employee.employee_assignments.within_date(Date.tomorrow)
```

```ruby
employee.employee_assignments.within_period(Date.current.beginning_of_month...Date.current.end_of_month)
```

Look up records starting with specific date with `from_date`

```ruby
employee.employee_assignments.from_date(Date.tomorrow)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/mak-it/periodic_records/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
