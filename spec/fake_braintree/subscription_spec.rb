require 'spec_helper'

describe 'Braintree::Subscription.create' do
  let(:plan_id)                { 'plan-id-from-braintree-control-panel' }
  let(:expiration_date)        { '04/2016' }

  it 'successfully creates a subscription' do
    subscription_result = Braintree::Subscription.create(
      payment_method_token: cc_token,
      plan_id: 'my_plan_id'
    )

    expect(subscription_result).to be_success
  end

  it 'assigns a Braintree-esque ID to the subscription' do
    expect(create_subscription.subscription.id).to match  /^[a-z0-9]{6}$/
  end

  it 'supports custom IDs' do
    expect(create_subscription('id' => 'custom1').subscription.id).to eq 'custom1'
  end

  it 'assigns unique IDs to each subscription' do
    cc_token_1 = cc_token
    cc_token_2 = braintree_credit_card_token(TEST_CC_NUMBER.sub('1', '5'), expiration_date)
    first_result = Braintree::Subscription.create(
      payment_method_token: cc_token_1,
      plan_id: plan_id
    )
    second_result = Braintree::Subscription.create(
      payment_method_token: cc_token_2,
      plan_id: plan_id
    )

    expect(first_result.subscription.id).not_to eq second_result.subscription.id
  end

  it 'stores created subscriptions in FakeBraintree.registry.subscriptions' do
    expect(FakeBraintree.registry.subscriptions[create_subscription.subscription.id]).not_to be_nil
  end

  context 'when associated credit card' do
    it 'adds this to its subscriptions' do
      subscription = create_subscription.subscription
      credit_card = Braintree::CreditCard.find(subscription.payment_method_token)
      expect(credit_card.subscriptions.length).to eq 1

      Braintree::Subscription.create(
        payment_method_token: credit_card.token,
        plan_id: 'my_plan_id'
      )
      credit_card = Braintree::CreditCard.find(subscription.payment_method_token)
      expect(credit_card.subscriptions.length).to eq 2
    end
  end

  it 'sets the next billing date to a string of 1.month.from_now in UTC' do
    Timecop.freeze do
      expect(create_subscription.subscription.next_billing_date).to eq 1.month.from_now.strftime('%Y-%m-%d')
    end
  end

  # according to https://developers.braintreepayments.com/javascript+ruby/reference/objects/subscription#subscription.billing-day-of-month
  it 'sets billing_day_of_month, keeping values in 1..28' do
    Timecop.freeze(Date.new(2014, 8, 28)) do
      expect(create_subscription.subscription.billing_day_of_month).to eq 28
    end
  end
  it 'sets billing_day_of_month, forcing value to 31 if outside of 1..28' do
    Timecop.freeze(Date.new(2014, 8, 29)) do
      expect(create_subscription.subscription.billing_day_of_month).to eq 31
    end
  end

  context 'without custom start date' do
    around do |example|
      Timecop.freeze(Date.new(2014, 8, 25), &example)
    end
    it 'sets billing_period_start_date to today' do
      expect(create_subscription.subscription.billing_period_start_date).to eq "2014-08-25"
    end
    it 'sets next_billing_date to one month from now' do
      expect(create_subscription.subscription.next_billing_date).to eq "2014-09-25"
    end
    it 'sets billing_period_end_date to one day before next_billing_date' do
      expect(create_subscription.subscription.billing_period_end_date).to eq "2014-09-24"
    end
  end

end

describe 'Braintree::Subscription.find' do
  it 'can find a created subscription' do
    payment_method_token = cc_token
    plan_id = 'abc123'
    subscription_id = create_subscription(
      payment_method_token: payment_method_token,
      plan_id: plan_id
    ).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    expect(subscription).to_not be_nil
    expect(subscription.payment_method_token).to eq payment_method_token
    expect(subscription.plan_id).to eq plan_id
  end

  it 'raises a Braintree:NotFoundError when it cannot find a subscription' do
    create_subscription
    expect { Braintree::Subscription.find('abc123') }.to raise_error(Braintree::NotFoundError, /abc123/)
  end

  it 'returns add-ons added with the subscription' do
    add_on_id = 'def456'
    amount = BigDecimal.new('20.00')
    subscription_id = create_subscription(add_ons: { add: [{ inherited_from_id: add_on_id, amount: amount }] }).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    add_ons = subscription.add_ons
    expect(add_ons.size).to eq 1
    expect(add_ons.first.id).to eq add_on_id
    expect(add_ons.first.amount).to eq amount
  end

  it 'returns discounts added with the subscription' do
    discount_id = 'def456'
    amount = BigDecimal.new('15.00')
    subscription_id = create_subscription(discounts: { add: [{ inherited_from_id: discount_id, amount: amount }]}).subscription.id
    subscription = Braintree::Subscription.find(subscription_id)
    discounts = subscription.discounts
    expect(discounts.size).to eq 1
    expect(discounts.first.id).to eq discount_id
    expect(discounts.first.amount).to eq amount
  end

  it 'finds subscriptions created with custom id' do
    create_subscription(id: 'bob-smiths-subscription')
    expect(Braintree::Subscription.find('bob-smiths-subscription')).to be_a Braintree::Subscription
  end

  it 'finds subscriptions created with custom integer id' do
    create_subscription(id: 1)
    expect(Braintree::Subscription.find(1)).to be_a Braintree::Subscription
  end
end

describe 'Braintree::Subscription.update' do
  it 'can update a subscription' do
    subscription_id = create_subscription.subscription.id

    Braintree::Subscription.update(subscription_id, plan_id: 'a_new_plan')
    expect(Braintree::Subscription.find(subscription_id).plan_id).to eq 'a_new_plan'
  end
end

describe 'Braintree::Subscription.retry_charge' do
  it 'can submit for settlement' do
    subscription_id = create_subscription.subscription.id

    authorized_transaction = Braintree::Subscription.retry_charge(subscription_id, 42.0).transaction
    result = Braintree::Transaction.submit_for_settlement(
      authorized_transaction.id
    )
    expect(result).to be_success
  end
end

describe 'Braintree::Subscription.cancel' do
  it 'can cancel a subscription' do
    subscription_id = create_subscription.subscription.id

    expect(Braintree::Subscription.cancel(subscription_id)).to be_success
    expect(Braintree::Subscription.find(subscription_id).status).to eq Braintree::Subscription::Status::Canceled
  end

  it 'cannot cancel an unknown subscription' do
    expect { Braintree::Subscription.cancel('totally-bogus-id') }.to raise_error(Braintree::NotFoundError)
  end
end
