require 'spec_helper'

describe "Braintree::CreditCard.find" do
  it "gets the correct credit card" do
    credit_card = Braintree::CreditCard.find(token)

    credit_card.last_4.should == TEST_CC_NUMBER[-4,4]
    credit_card.expiration_month.should == month
    credit_card.expiration_year.should ==  year
  end

  let(:month) { '04' }
  let(:year)  { '2016' }
  let(:token) { braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/')) }
end

describe "Braintree::CreditCard.create" do
  let(:month) { '04' }
  let(:year)  { '2016' }
  let(:token) { braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/')) }
  it "successfully creates card with valid data" do
    result = Braintree::CreditCard.create :token => token,
      :number => TEST_CC_NUMBER
    result.should be_success

    Braintree::CreditCard.find(token).should be
  end
end

describe "Braintree::CreditCard.sale" do
  it "successfully creates a sale" do
    result = Braintree::CreditCard.sale(cc_token, :amount => 10.00)
    result.should be_success
    Braintree::Transaction.find(result.transaction.id).should be
  end
end

describe "Braintree::CreditCard.update" do
  it "successfully updates the credit card" do
    new_expiration_date = "08/2012"
    token = cc_token

    result = Braintree::CreditCard.update(token, :expiration_date => new_expiration_date)
    result.should be_success
    Braintree::CreditCard.find(token).expiration_date.should == new_expiration_date
  end

  it "raises an error for a nonexistent credit card" do
    lambda { Braintree::CreditCard.update("foo", {:number => TEST_CC_NUMBER}) }.should raise_error(Braintree::NotFoundError)
  end
end
