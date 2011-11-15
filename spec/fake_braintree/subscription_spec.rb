require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context "Braintree::Subscription.create" do
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

    it "sets the next billing date to 1 month from now in UTC" do
      Timecop.freeze do
        result = Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                                :plan_id => plan_id)

        result.subscription.next_billing_date.to_i.should == 1.month.from_now.utc.to_i
      end
    end
  end

  context "Braintree::Subscription.find" do
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

    it "can find the associated customer" do
      subscription = Braintree::Subscription.find(subscription_result.subscription.id)
      subscription.payment_method_token.should == payment_method_token
    end
  end
end
