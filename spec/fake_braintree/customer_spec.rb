require 'spec_helper'

describe FakeBraintree::SinatraApp, "Braintree::Customer.create" do
  let(:cc_number)       { %w(4111 1111 1111 1111).join }
  let(:expiration_date) { "04/2016" }
  after { FakeBraintree.verify_all_cards = false }

  def create_customer_with_credit_card(options)
    Braintree::Customer.create(:credit_card => options)
  end

  it "successfully creates a customer" do
    result = create_customer_with_credit_card(:number => cc_number,
                                              :expiration_date => expiration_date)
    result.should be_success
  end

  it "records the billing address" do
    result = create_customer_with_credit_card(
      :number => cc_number,
      :expiration_date => expiration_date,
      :billing_address => {
        :street_address => "1 E Main St",
        :extended_address => "Suite 3",
        :locality => "Chicago",
        :region => "Illinois",
        :postal_code => "60622",
        :country_code_alpha2 => "US"
      }
    )

    billing_address = result.customer.credit_cards[0].billing_address

    billing_address.street_address.should == "1 E Main St"
    billing_address.postal_code.should == "60622"
  end

  context "when passed :verify_card => true" do
    it "accepts valid cards" do
      create_customer_with_credit_card(
        :number          => cc_number,
        :expiration_date => expiration_date,
        :options         => { :verify_card => true }
      ).should be_success
    end

    it "rejects invalid cards" do
      create_customer_with_credit_card(
        :number          => '123456',
        :expiration_date => expiration_date,
        :options         => { :verify_card => true }
      ).should_not be_success
    end
  end

  context "when FakeBraintree.verify_all_cards == true" do
    before { FakeBraintree.verify_all_cards! }

    it "accepts valid cards" do
      create_customer_with_credit_card(
        :number          => cc_number,
        :expiration_date => expiration_date
      ).should be_success
    end

    it "rejects invalid cards" do
      create_customer_with_credit_card(
        :number          => '123456',
        :expiration_date => expiration_date
      ).should_not be_success
    end
  end
end
