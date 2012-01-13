require 'spork'

Spork.prefork do
  require 'rspec'
  require 'fake_braintree'
  require 'timecop'
  require 'bourne'

  def clear_braintree_log
    Dir.mkdir('tmp') unless File.directory?('tmp')
    File.new('tmp/braintree_log', 'w').close
  end

  Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

  clear_braintree_log

  TEST_CC_NUMBER = %w(4111 1111 1111 1111).join

  RSpec.configure do |config|
    config.mock_with :mocha

    config.include BraintreeHelpers
    config.include CustomerHelpers
    config.include SubscriptionHelpers

    config.before do
      FakeBraintree.clear!
      FakeBraintree.verify_all_cards = false
    end
  end
end

Spork.each_run do
end
