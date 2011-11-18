require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context "Braintree::CreditCard.find" do
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

  context "Braintree::CreditCard.sale" do
    it "successfully creates a sale" do
      result = Braintree::CreditCard.sale(cc_token, :amount => 10.00)
      result.should be_success
      Braintree::Transaction.find(result.transaction.id).should be
    end
  end
end
