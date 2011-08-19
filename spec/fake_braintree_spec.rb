require 'spec_helper'

describe FakeBraintree, ".credit_card_from_token" do
  let(:cc_number)         { %w(4111 1111 1111 9876).join }
  let(:cc_number_2)       { %w(4111 1111 1111 2222).join }
  let(:expiration_date)   { "04/2016" }
  let(:expiration_date_2) { "05/2019" }
  let(:token)             { braintree_credit_card_token(cc_number, expiration_date) }
  let(:token_2)           { braintree_credit_card_token(cc_number_2, expiration_date_2) }

  it "looks up the credit card based on a CC token" do
    credit_card = FakeBraintree.credit_card_from_token(token)
    credit_card["last_4"].should == "9876"
    credit_card["expiration_year"].should == "2016"
    credit_card["expiration_month"].should == "04"

    credit_card = FakeBraintree.credit_card_from_token(token_2)
    credit_card["last_4"].should == "2222"
    credit_card["expiration_year"].should == "2019"
    credit_card["expiration_month"].should == "05"
  end
end

describe FakeBraintree, ".decline_all_cards!" do
  let(:cc_number)       { %w(4111 1111 1111 9876).join }
  let(:expiration_date) { "04/2016" }
  let(:token)           { braintree_credit_card_token(cc_number, expiration_date) }
  let(:amount)          { 10.00 }

  before do
    FakeBraintree.decline_all_cards!
  end

  it "declines all cards" do
    result = Braintree::CreditCard.sale(token, amount: amount)
    result.should_not be_success
  end

  it "stops declining cards after clear! is called" do
    FakeBraintree.clear!
    result = Braintree::CreditCard.sale(token, amount: amount)
    result.should be_success
  end
end
