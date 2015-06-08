require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'fake_braintree/client_assets'
require 'fake_braintree/dropin_assets'

RSpec::Core::RakeTask.new(:spec)

desc 'Run specs'
task default: [:spec]

desc 'Update assets'
task :update_assets do
  client_assets = FakeBraintree::ClientAssets.new
  client_assets.save

  dropin_version = client_assets.dropin_version
  FakeBraintree::DropinAssets.new(dropin_version).save
end

desc 'Update braintree client'
task :update_braintree do
  FakeBraintree::ClientAssets.new.save
end

desc 'Update braintree drop-in assets'
task :update_dropin do
  dropin_version = FakeBraintree::ClientAssets.new.dropin_version
  FakeBraintree::DropinAssets.new(dropin_version).save
end
