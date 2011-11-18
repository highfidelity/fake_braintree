require 'spork'

Spork.prefork do
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  require 'rspec'
  require 'fake_braintree'
  require 'timecop'
  Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

  Dir.mkdir('tmp') unless File.directory?('tmp')
  File.new('tmp/braintree_log', 'w').close

  TEST_CC_NUMBER = %w(4111 1111 1111 1111).join

  RSpec.configure do |config|
    config.mock_with :mocha

    config.include BraintreeHelpers
    config.include CustomerHelpers

    config.before do
      FakeBraintree.clear!
      FakeBraintree.verify_all_cards = false
    end
  end
end

Spork.each_run do
end
