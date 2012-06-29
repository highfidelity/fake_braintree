require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  # Don't include Braintree integration specs
  t.pattern = 'spec/{fake_braintree*/**.rb}'
end

RSpec::Core::RakeTask.new(:braintree_integration) do |t|
  # Include Braintree integration specs
  t.pattern = 'spec/integration_spec.rb'
end

desc 'Run specs'
task :default => [:spec, :braintree_integration]
