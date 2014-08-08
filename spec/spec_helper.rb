require 'bundler'

Bundler.require

require 'rspec'
require 'fake_braintree'
require 'timecop'

def clear_braintree_log
  path = File.expand_path("./tmp/braintree_log")
  FileUtils.mkdir_p(File.dirname(path))
  logger = Logger.new(path)
  logger.level = Logger::DEBUG
  Braintree::Configuration.logger = logger
end

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

clear_braintree_log

TEST_CC_NUMBER = %w(4111 1111 1111 1111).join

RSpec.configure do |config|
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random

  config.include BraintreeHelpers
  config.include CustomerHelpers
  config.include SubscriptionHelpers
  config.include FakeBraintree::Helpers

  config.before do
    FakeBraintree.clear!
    FakeBraintree.verify_all_cards = false
  end
end
