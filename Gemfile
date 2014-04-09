source 'http://rubygems.org'

# Web servers for different platforms

platform :jruby do
  gem 'puma'
end

platform :mri do
  gem 'thin'
end

# Specify your gem's dependencies in fake_braintree.gemspec
gemspec

# Capybara 2.1.0 requires 1.9.3+ so we install a version that works with
# every Ruby version we test against. This can be removed if we stop testing
# against 1.9.2.
gem 'capybara', '~> 2.0.3'

if RUBY_VERSION == '1.9.2'
  gem 'activesupport', '< 4.0'
end
