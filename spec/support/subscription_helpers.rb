module SubscriptionHelpers
  def create_subscription(user_options = {})
    options = {
      payment_method_token: cc_token,
      plan_id: 'my_plan_id'
    }.merge(user_options)

    Braintree::Subscription.create(options)
  end

  def update_subscription(subscription_id, user_options = {})
    Braintree::Subscription.update(subscription_id, user_options)
  end
end
