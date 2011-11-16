require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.sale" do
    it "successfully creates a transaction" do
      result = Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => 10.00)
      result.should be_success
    end
  end
end

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.find" do
    it "can find a created sale" do
      id = create_transaction.id
      result = Braintree::Transaction.find(id)
      result.amount.should == amount
    end

    it "can find >1 transaction" do
      result_one = Braintree::Transaction.find(create_transaction.id)
      result_two = Braintree::Transaction.find(create_transaction.id)
      result_one.should be
      result_two.should be
    end

    def create_transaction
      Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => amount).transaction
    end

    let(:amount) { 10.00 }
  end
end
