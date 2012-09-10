require 'spec_helper'

describe "Braintree::Subscription.create" do
  let(:plan_id)                { 'plan-id-from-braintree-control-panel' }
  let(:expiration_date)        { "04/2016" }

  it "successfully creates a subscription" do
    Braintree::Subscription.create(:payment_method_token => cc_token,
                                   :plan_id => 'my_plan_id').should be_success
  end

  it "assigns a Braintree-esque ID to the subscription" do
    create_subscription.subscription.id.should =~ /^[a-z0-9]{6}$/
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

  it "stores created subscriptions in FakeBraintree.registry.subscriptions" do
    FakeBraintree.registry.subscriptions[create_subscription.subscription.id].should_not be_nil
  end

  it "sets the next billing date to a string of 1.month.from_now in UTC" do
    Timecop.freeze do
      create_subscription.subscription.next_billing_date.should == 1.month.from_now.strftime('%Y-%m-%d')
    end
  end
end

describe "Braintree::Subscription.find" do
  it "can find a created subscription" do
    payment_method_token = cc_token
    plan_id = "abc123"
    subscription_id =
      create_subscription(:payment_method_token => payment_method_token, :plan_id => plan_id).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    subscription.should_not be_nil
    subscription.payment_method_token.should == payment_method_token
    subscription.plan_id.should == plan_id
  end

  it "raises a Braintree:NotFoundError when it cannot find a subscription" do
    create_subscription
    expect { Braintree::Subscription.find('abc123') }.to raise_error(Braintree::NotFoundError, /abc123/)
  end

  it "returns add-ons added with the subscription" do
    add_on_id = "def456"
    subscription_id = create_subscription(:add_ons => { :add => [{ :inherited_from_id => add_on_id }] }).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    add_ons = subscription.add_ons
    add_ons.size.should == 1
    add_ons.first.id.should == add_on_id
  end

  it "returns discounts added with the subscription" do
    discount_id = "def456"
    subscription_id = create_subscription(:discounts => { :add => [{ :inherited_from_id => discount_id, :amount => BigDecimal.new("15.00") }]}).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    discounts = subscription.discounts
    discounts.size.should == 1
    discounts.first.id.should == discount_id
  end
end

describe "Braintree::Subscription.update" do
  it "can update a subscription" do
    Braintree::Subscription.update(subscription_id, :plan_id => 'a_new_plan')
    Braintree::Subscription.find(subscription_id).plan_id.should == 'a_new_plan'
  end

  let(:subscription_id) { subscription.subscription.id }
  let(:subscription)    { create_subscription }
end

describe "Braintree::Subscription.cancel" do
  it "can cancel a subscription" do
    Braintree::Subscription.cancel(subscription_id).should be_success
    Braintree::Subscription.find(subscription_id).status.should == Braintree::Subscription::Status::Canceled
  end

  it "can't cancel an unknown subscription" do
    expect { Braintree::Subscription.cancel("totally-bogus-id") }.to raise_error(Braintree::NotFoundError)
  end

  let(:subscription_id) { subscription.subscription.id }
  let(:subscription)    { create_subscription }
end
