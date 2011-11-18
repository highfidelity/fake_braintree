require 'spec_helper'

describe "Braintree::Subscription.create" do
  let(:plan_id)                { 'plan-id-from-braintree-control-panel' }
  let(:expiration_date)        { "04/2016" }

  it "successfully creates a subscription" do
    result = Braintree::Subscription.create(:payment_method_token => cc_token,
                                            :plan_id => plan_id)
    result.should be_success
  end

  it "assigns a Braintree-esque ID to the subscription" do
    result = Braintree::Subscription.create(:payment_method_token => cc_token,
                                            :plan_id => plan_id)

    result.subscription.id.should =~ /^[a-z0-9]{6}$/
  end

  it "assigns unique IDs to each subscription" do
    cc_token_1 = cc_token
    cc_token_2 = braintree_credit_card_token(TEST_CC_NUMBER.sub('1', '5'), expiration_date)
    first_result = Braintree::Subscription.create(:payment_method_token => cc_token_1,
                                                  :plan_id => plan_id)
    second_result = Braintree::Subscription.create(:payment_method_token => cc_token_2,
                                                   :plan_id => plan_id)

    first_result.subscription.id.should_not == second_result.subscription.id
  end

  it "sets the next billing date to 1 month from now in UTC" do
    Timecop.freeze do
      result = Braintree::Subscription.create(:payment_method_token => cc_token,
                                              :plan_id => plan_id)

      result.subscription.next_billing_date.to_i.should == 1.month.from_now.utc.to_i
    end
  end
end

describe "Braintree::Subscription.find" do

  it "can find a created subscription" do
    subscription = Braintree::Subscription.find(subscription_id)
    subscription.should_not be_nil
    subscription.payment_method_token.should == payment_method_token
    subscription.plan_id.should == plan_id
  end

  it "raises a Braintree:NotFoundError when it cannot find a subscription" do
    expect { Braintree::Subscription.find('abc123') }.to raise_error(Braintree::NotFoundError, /abc123/)
  end

  let(:payment_method_token) { cc_token }
  let(:plan_id)              { 'my-plan-id' }
  let(:subscription_id)  { Braintree::Subscription.create(:payment_method_token => payment_method_token,
                                                          :plan_id => plan_id).subscription.id }
end
