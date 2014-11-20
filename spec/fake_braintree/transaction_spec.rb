require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.sale' do
    it 'successfully creates a transaction' do
      result = Braintree::Transaction.sale(
        payment_method_token: cc_token,
        amount: 10.00
      )
      expect(result).to be_success
      expect(result.transaction.type).to eq 'sale'
    end

    context 'when all cards are declined' do
      before { FakeBraintree.decline_all_cards! }

      it 'fails' do
        result = Braintree::Transaction.sale(
          payment_method_token: cc_token,
          amount: 10.00
        )
        expect(result).to_not be_success
      end
    end

    context "when the options hash is nil" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(payment_method_token: cc_token, amount: 10.00)
        expect(result.transaction.status).to eq 'authorized'
      end
    end

    context "when submit_for_settlement is not true" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(
          payment_method_token: cc_token,
          amount: 10.00,
          options: {
            submit_for_settlement: false
          }
        )
        expect(result.transaction.status).to eq 'authorized'
      end
    end

    context "when submit_for_settlement does not exist" do
      it "returns a transaction with a status of authorized" do
        result = Braintree::Transaction.sale(
          payment_method_token: cc_token,
          amount: 10.00,
          options: {
            add_billing_address_to_payment_method: true
          }
        )
        expect(result.transaction.status).to eq 'authorized'
      end
    end

    context "when submit_for_settlement is true" do
      it "returns a transaction with a status of submitted_for_settlement" do
        result = Braintree::Transaction.sale(
          payment_method_token: cc_token,
          amount: 10.00,
          options: {
            submit_for_settlement: true
          }
        )
        expect(result.transaction.status).to eq 'submitted_for_settlement'
      end
    end
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.refund' do
    it 'successfully refunds a transaction' do
      result = Braintree::Transaction.refund(create_id('foobar'), '1')
      expect(result).to be_success
    end
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.void' do
    it 'successfully voids a transaction' do
      sale = Braintree::Transaction.sale(
        payment_method_token: cc_token,
        amount: 10.00
      )
      p FakeBraintree.registry.transactions
      result = Braintree::Transaction.void(sale.transaction.id)
      expect(result).to be_success
      expect(result.transaction.status).to eq Braintree::Transaction::Status::Voided
    end
  end
end

describe FakeBraintree::SinatraApp do
  context 'Braintree::Transaction.find' do
    it 'can find a created sale' do
      id = create_transaction(10.00).id
      result = Braintree::Transaction.find(id)
      expect(result.amount).to eq 10.00
    end

    it 'can find >1 transaction' do
      expect(Braintree::Transaction.find(create_transaction.id)).to be
      expect(Braintree::Transaction.find(create_transaction.id)).to be
    end

    it 'raises an error when the transaction does not exist' do
      expect { Braintree::Transaction.find('foobar') }.to raise_error(Braintree::NotFoundError)
    end

    def create_transaction(amount = 10.00)
      Braintree::Transaction.sale(
        payment_method_token: cc_token,
        amount: amount
      ).transaction
    end
  end
end

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.submit_for_settlement" do
    it "should be able to mark transaction as completed" do
      id = create_transaction.id

      result = Braintree::Transaction.submit_for_settlement(id)

      expect(result).to be_success
      expect(Braintree::Transaction.find(id).status).to eq Braintree::Transaction::Status::SubmittedForSettlement
    end

    def create_transaction
      Braintree::Transaction.sale(payment_method_token: cc_token, amount: 10.0).transaction
    end
  end
end
