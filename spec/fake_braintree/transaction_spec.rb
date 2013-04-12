require 'spec_helper'

shared_examples "a failable transaction" do
  it 'returns an error if we ask it to and resets the failure to nil' do
    message = 'some error'
    FakeBraintree.fail_next_transaction_with(message)
    result = Braintree::Transaction.send(transaction_method,*transaction_method_args)
    result.should_not be_success
    result.message.should == message
    FakeBraintree.fail_next_transaction?.should == false
  end

  after :each do
    FakeBraintree.fail_next_transaction_with(nil)
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.sale' do
    it 'successfully creates a transaction' do
      result = Braintree::Transaction.sale(
        :payment_method_token => cc_token,
        :amount => 10.00
      )
      result.should be_success
      result.transaction.type.should == 'sale'
    end

    it_behaves_like 'a failable transaction' do
      let(:transaction_method) { :sale }
      let(:transaction_method_args) { [{ :payment_method_token => cc_token, :amount => 10.00 }] }
    end

    context 'when all cards are declined' do
      before { FakeBraintree.decline_all_cards! }

      it 'fails' do
        result = Braintree::Transaction.sale(
          :payment_method_token => cc_token,
          :amount => 10.00
        )
        result.should_not be_success
      end
    end

    context "when the options hash is nil" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => 10.00)
        result.transaction.status.should == 'authorized'
      end
    end

    context "when submit_for_settlement is not true" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(
          :payment_method_token => cc_token,
          :amount => 10.00,
          :options => {
            :submit_for_settlement => false
          }
        )
        result.transaction.status.should == 'authorized'
      end
    end

    context "when submit_for_settlement does not exist" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(
          :payment_method_token => cc_token,
          :amount => 10.00,
          :options => {
            :add_billing_address_to_payment_method => true
          }
        )
        result.transaction.status.should == 'authorized'
      end
    end

    context "when submit_for_settlement is true" do
      it "returns a transaction with a status of submitted_for_settlement" do
        result = Braintree::Transaction.sale(
          :payment_method_token => cc_token,
          :amount => 10.00,
          :options => {
            :submit_for_settlement => true
          }
        )
        result.transaction.status.should == 'submitted_for_settlement'
      end
    end
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.refund' do
    it 'successfully refunds a transaction' do
      result = Braintree::Transaction.refund(create_id('foobar'), '1')
      result.should be_success
    end

    it_behaves_like 'a failable transaction' do
      let(:transaction_method) { :refund }
      let(:transaction_method_args) { [create_id('foobar'), '1'] }
    end
  end
end

describe FakeBraintree::SinatraApp do
  let!(:sale_transaction_id) {
    FakeBraintree.fail_next_transaction_with(nil)
    Braintree::Transaction.sale(
      :payment_method_token => cc_token,
      :amount => 10.00
    ).transaction.id
  }
  context 'Braintree::Transaction.void' do
    it 'successfully voids a transaction' do
      result = Braintree::Transaction.void(sale_transaction_id)
      result.should be_success
      result.transaction.status.should == Braintree::Transaction::Status::Voided
    end

    it_behaves_like 'a failable transaction' do
      let(:transaction_method) { :void }
      let(:transaction_method_args) { [sale_transaction_id] }
    end
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.find' do
    it 'can find a created sale' do
      id = create_transaction.id
      result = Braintree::Transaction.find(id)
      result.amount.should == amount
    end

    it 'can find >1 transaction' do
      Braintree::Transaction.find(create_transaction.id).should be
      Braintree::Transaction.find(create_transaction.id).should be
    end

    it 'raises an error when the transaction does not exist' do
      expect { Braintree::Transaction.find('foobar') }.to raise_error(Braintree::NotFoundError)
    end

    def create_transaction
      Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => amount).transaction
    end

    let(:amount) { 10.00 }
  end
end
