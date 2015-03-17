require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Run specs'
task default: [:spec]

desc 'Update assets'
task update_assets: [:update_braintree, :update_dropin]

desc 'Update braintree client'
task :update_braintree do
  version = FakeBraintree::BRAINTREE_VERSION
  puts 'Downloading braintree.js'

  origin = "https://js.braintreegateway.com/v2/braintree.js"
  target = 'spec/dummy/public/braintree.js'
  sh "curl #{origin} -o #{target}"
end

desc 'Update braintree drop-in assets'
task :update_dropin do
  version = FakeBraintree::DROPIN_VERSION
  rm_rf('lib/fake_braintree/braintree_assets/dropin')

  origin_root = "https://assets.braintreegateway.com/dropin/#{version}/"
  target_root = "lib/fake_braintree/braintree_assets/dropin/#{version}/"
  [
    'braintree-dropin-internal.min.js',
    'braintree-dropin.css',
    'inline-frame.html',
    'modal-frame.html',
    'vendor/jquery-2.1.0.js',
    'vendor/modernizr.js',
    'vendor/normalize.css', 
    'images/2x-sf9a66b4f5a.png'
  ].each do |path|
    puts "Downloading #{path}"
    sh "curl #{origin_root + path} -o #{target_root + path} --create-dirs"
  end
end
