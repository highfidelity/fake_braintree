require 'braintree'
require 'digest/md5'
require 'sham_rack'
require 'sinatra'
require 'active_support'
require 'active_support/core_ext'

require 'fake_braintree/sinatra_app'
require 'fake_braintree/version'

Braintree::Configuration.logger = Logger.new("tmp/log")

module FakeBraintree
  class << self
    @customers     = {}
    @subscriptions = {}
    @failures      = {}
    @transaction   = {}

    @decline_all_cards = false
    attr_accessor :customers, :subscriptions, :failures, :transaction, :decline_all_cards
  end

  def self.activate!
    Braintree::Configuration.environment = :production
    Braintree::Configuration.merchant_id = "xxx"
    Braintree::Configuration.public_key  = "xxx"
    Braintree::Configuration.private_key = "xxx"
    clear!
    ShamRack.mount(FakeBraintree::SinatraApp, "www.braintreegateway.com", 443)
  end

  def self.clear!
    self.customers         = {}
    self.subscriptions     = {}
    self.failures          = {}
    self.transaction       = {}
    self.decline_all_cards = false
  end

  def self.failure?(card_number)
    self.failures.include?(card_number)
  end

  def self.failure_response(card_number)
    failure = self.failures[card_number]
    failure["errors"] ||= { "errors" => [] }

    { "message"      => failure["message"],
      "verification" => { "status"                   => failure["status"],
                          "processor_response_text"  => failure["message"],
                          "processor_response_code"  => failure["code"],
                          "gateway_rejection_reason" => "cvv",
                          "cvv_response_code"        => failure["code"] },
      "errors"        => failure["errors"],
      "params"        => {}}
  end

  def self.create_failure
    { "message"      => "Do Not Honor",
      "verification" => { "status"                  => "processor_declined",
                          "processor_response_text" => "Do Not Honor",
                          "processor_response_code" => '2000' },
      "errors"       => { 'errors' => [] },
      "params"       => {} }
  end

  def self.decline_all_cards!
    self.decline_all_cards = true
  end

  def self.decline_all_cards?
    self.decline_all_cards
  end

  def self.credit_card_from_token(token)
    self.customers.values.detect do |customer|
      next unless customer.key?("credit_cards")

      card = customer["credit_cards"].detect {|card| card["token"] == token }
      return card if card
    end
  end

  def self.generated_transaction
    {"status_history"=>[{"timestamp"=>Time.now,
                         "amount"=>FakeBraintree.transaction[:amount],
                         "transaction_source"=>"CP",
                         "user"=>"copycopter",
                         "status"=>"authorized"},
                        {"timestamp"=>Time.now,
                         "amount"=>FakeBraintree.transaction[:amount],
                         "transaction_source"=>"CP",
                         "user"=>"copycopter",
                         "status"=>FakeBraintree.transaction[:status]}],
                         "created_at"=>(FakeBraintree.transaction[:created_at] || Time.now),
                         "currency_iso_code"=>"USD",
                         "settlement_batch_id"=>nil,
                         "processor_authorization_code"=>"ZKB4VJ",
                         "avs_postal_code_response_code"=>"I",
                         "order_id"=>nil,
                         "updated_at"=>Time.now,
                         "refunded_transaction_id"=>nil,
                         "amount"=>FakeBraintree.transaction[:amount],
                         "credit_card"=>{"last_4"=>"1111",
                                         "card_type"=>"Visa",
                                         "token"=>"8yq7",
                                         "customer_location"=>"US",
                                         "expiration_year"=>"2013",
                                         "expiration_month"=>"02",
                                         "bin"=>"411111",
                                         "cardholder_name"=>"Chad Lee Pytel"
                                        },
                          "refund_id"=>nil,
                          "add_ons"=>[],
                          "shipping"=>{"region"=>nil,
                                       "company"=>nil,
                                       "country_name"=>nil,
                                       "extended_address"=>nil,
                                       "postal_code"=>nil,
                                       "id"=>nil,
                                       "street_address"=>nil,
                                       "country_code_numeric"=>nil,
                                       "last_name"=>nil,
                                       "locality"=>nil,
                                       "country_code_alpha2"=>nil,
                                       "country_code_alpha3"=>nil,
                                       "first_name"=>nil},
                            "id"=>"49sbx6",
                            "merchant_account_id"=>"Thoughtbot",
                            "type"=>"sale",
                            "cvv_response_code"=>"I",
                            "subscription_id"=>FakeBraintree.transaction[:subscription_id],
                            "custom_fields"=>"\n",
                            "discounts"=>[],
                            "billing"=>{"region"=>nil,
                                        "company"=>nil,
                                        "country_name"=>nil,
                                        "extended_address"=>nil,
                                        "postal_code"=>nil,
                                        "id"=>nil,
                                        "street_address"=>nil,
                                        "country_code_numeric"=>nil,
                                        "last_name"=>nil,
                                        "locality"=>nil,
                                        "country_code_alpha2"=>nil,
                                        "country_code_alpha3"=>nil,
                                        "first_name"=>nil},
                            "processor_response_code"=>"1000",
                            "refund_ids"=>[],
                            "customer"=>{"company"=>nil,
                                          "id"=>"108427",
                                          "last_name"=>nil,
                                          "fax"=>nil,
                                          "phone"=>nil,
                                          "website"=>nil,
                                          "first_name"=>nil,
                                          "email"=>"cpytel@thoughtbot.com" },
                            "avs_error_response_code"=>nil,
                            "processor_response_text"=>"Approved",
                            "avs_street_address_response_code"=>"I",
                            "status"=>FakeBraintree.transaction[:status],
                            "gateway_rejection_reason"=>nil}
  end
end
