# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'periodic_records/version'

Gem::Specification.new do |spec|
  spec.name          = "periodic_records"
  spec.version       = PeriodicRecords::VERSION
  spec.authors       = ["Edgars Beigarts", "Toms Mikoss"]
  spec.email         = ["edgars.beigarts@mitigate.dev", "toms.mikoss@mitigate.dev"]

  spec.summary       = %q{Support functions for ActiveRecord models with periodic entries}
  spec.description   = %q{Support functions for ActiveRecord models with periodic entries}
  spec.homepage      = "https://github.com/mak-it/periodic_records"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 3.1.0'

  spec.add_runtime_dependency "activerecord", ">= 6.1"
  spec.add_runtime_dependency "activesupport", ">= 6.1"

  spec.add_development_dependency "bundler", ">= 1.9"
  spec.add_development_dependency "rake", "~> 13.1"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "sqlite3"
end
