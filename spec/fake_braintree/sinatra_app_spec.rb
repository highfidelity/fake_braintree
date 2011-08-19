require 'spec_helper'

module FakeBraintree
  describe SinatraApp, "Braintree::CreditCard.find" do
    let(:cc_number)         { %w(4111 1111 1111 9876).join }
    let(:expiration_date)   { "04/2016" }
    let(:token)             { braintree_credit_card_token(cc_number, expiration_date) }

    it "gets the correct credit card" do
      credit_card = Braintree::CreditCard.find(token)

      credit_card.last_4.should == "9876"
      credit_card.expiration_year.should == "2016"
      credit_card.expiration_month.should == "04"
    end
  end

  describe SinatraApp, "Braintree::CreditCard.sale" do
    let(:cc_number)         { %w(4111 1111 1111 9876).join }
    let(:expiration_date)   { "04/2016" }
    let(:token)             { braintree_credit_card_token(cc_number, expiration_date) }
    let(:amount)            { 10.00 }

    it "successfully creates a sale" do
      result = Braintree::CreditCard.sale(token, amount: amount, options: {submit_for_settlement: true})
      result.should be_success

      Braintree::Transaction.find(result.transaction.id).should be
      lambda { Braintree::Transaction.find("foo") }.should raise_error(Braintree::NotFoundError)
    end
  end
end
