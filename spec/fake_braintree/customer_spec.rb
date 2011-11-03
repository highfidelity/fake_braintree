require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context "Braintree::Customer.create" do
    let(:cc_number)       { %w(4111 1111 1111 1111).join }
    let(:expiration_date) { "04/2016" }
    after { FakeBraintree.verify_all_cards = false }

    it "successfully creates a customer" do
      result = Braintree::Customer.create(
        :credit_card => {
          :number          => cc_number,
          :expiration_date => expiration_date
        })

      result.should be_success
    end

    it "verifies the card number when passed :verify_card => true" do
      Braintree::Customer.create(
        :credit_card => {
          :number          => cc_number,
          :expiration_date => expiration_date,
          :options         => { :verify_card => true }
        }).should be_success

      Braintree::Customer.create(
        :credit_card => {
          :number          => '123456',
          :expiration_date => expiration_date,
          :options         => { :verify_card => true }
        }).should_not be_success
    end

    it "verifies the card number when FakeBraintree.verify_all_cards == true" do
      FakeBraintree.verify_all_cards!

      Braintree::Customer.create(
        :credit_card => {
          :number          => cc_number,
          :expiration_date => expiration_date
        }).should be_success

      Braintree::Customer.create(
        :credit_card => {
          :number          => '123456',
          :expiration_date => expiration_date
        }).should_not be_success
    end
  end
end
