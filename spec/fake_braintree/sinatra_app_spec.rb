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

  describe SinatraApp, "Braintree::Subscription.create" do
    let(:plan_id)                { 'plan-id-from-braintree-control-panel' }
    let(:cc_number)              { %w(4111 1111 1111 9876).join }
    let(:expiration_date)        { "04/2016" }
    let(:payment_method_token)   { braintree_credit_card_token(cc_number, expiration_date) }
    let(:payment_method_token_2) { braintree_credit_card_token(cc_number.sub('1', '5'), expiration_date) }

    it "successfully creates a subscription" do
      result = Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                              :plan_id => plan_id)
      result.should be_success
    end

    it "assigns a Braintree-esque ID to the subscription" do
      result = Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                              :plan_id => plan_id)

      result.subscription.id.should =~ /^[a-z0-9]{6}$/
    end

    it "assigns unique IDs to each subscription" do
      first_result = Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                                    :plan_id => plan_id)
      second_result = Braintree::Subscription.create(:payment_method_token => payment_method_token_2,
                                                     :plan_id => plan_id)

      first_result.subscription.id.should_not == second_result.subscription.id
    end
  end

  describe SinatraApp, "Braintree::Subscription.find" do
    let(:cc_number)            { %w(4111 1111 1111 9876).join }
    let(:expiration_date)      { "04/2016" }
    let(:payment_method_token) { braintree_credit_card_token(cc_number, expiration_date) }
    let(:subscription_result)  { Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                                                :plan_id => 'my-plan-id') }

    it "can find a created subscription" do
      Braintree::Subscription.find(subscription_result.subscription.id).should be
    end

    it "raises a Braintree:NotFoundError when it cannot find a subscription" do
      expect { Braintree::Subscription.find('abc123') }.to raise_error(Braintree::NotFoundError, /abc123/)
    end
  end

  describe SinatraApp, "Braintree::Customer.create" do
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
