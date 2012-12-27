require 'fileutils'
require 'braintree'
require 'active_support/core_ext/module/attribute_accessors'

require 'fake_braintree/helpers'
require 'fake_braintree/customer'
require 'fake_braintree/subscription'
require 'fake_braintree/redirect'
require 'fake_braintree/credit_card'

require 'fake_braintree/registry'
require 'fake_braintree/server'
require 'fake_braintree/sinatra_app'
require 'fake_braintree/valid_credit_cards'
require 'fake_braintree/version'

module FakeBraintree
  mattr_accessor :registry, :verify_all_cards, :decline_all_cards

  def self.activate!
    initialize_registry
    self.verify_all_cards = false
    set_configuration
    clear!
    boot_server
  end

  def self.log_file_path
    'tmp/log'
  end

  def self.clear!
    self.registry.clear!
    self.decline_all_cards = false
    clear_log!
  end

  def self.clear_log!
    FileUtils.mkdir_p(File.dirname(log_file_path))
    File.new(log_file_path, 'w').close
  end

  def self.failure?(card_number)
    registry.failure?(card_number)
  end

  def self.failure_response(card_number = nil)
    failure = registry.failures[card_number] || {}
    failure['errors'] ||= { 'errors' => [] }

    { 'message'      => failure['message'],
      'verification' => { 'status'                   => failure['status'],
                          'processor_response_text'  => failure['message'],
                          'processor_response_code'  => failure['code'],
                          'gateway_rejection_reason' => 'cvv',
                          'cvv_response_code'        => failure['code'] },
      'errors'        => failure['errors'],
      'params'        => {}}
  end

  def self.create_failure
    {
      'message'      => 'Do Not Honor',
      'verification' => { 'status'                  => 'processor_declined',
                          'processor_response_text' => 'Do Not Honor',
                          'processor_response_code' => '2000' },
      'errors'       => { 'errors' => [] },
      'params'       => {}
    }
  end

  def self.decline_all_cards!
    self.decline_all_cards = true
  end

  def self.decline_all_cards?
    decline_all_cards
  end

  def self.verify_all_cards!
    self.verify_all_cards = true
  end

  def self.generate_transaction(options = {})
    history_item = {
      'timestamp' => Time.now,
      'amount' => options[:amount],
      'status' => options[:status]
    }
    created_at = options[:created_at] || Time.now
    {
      'status_history'  => [history_item],
      'subscription_id' => options[:subscription_id],
      'created_at' => created_at,
      'amount' => options[:amount]
    }
  end

  private

  def self.set_configuration
    Braintree::Configuration.environment = :development
    Braintree::Configuration.merchant_id = 'xxx'
    Braintree::Configuration.public_key  = 'xxx'
    Braintree::Configuration.private_key = 'xxx'
  end

  def self.boot_server
    Server.new.boot
  end

  def self.initialize_registry
    self.registry = Registry.new
  end
end

FakeBraintree.activate!
Braintree::Configuration.logger = Logger.new(FakeBraintree.log_file_path)
