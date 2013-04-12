module SubscriptionHelpers
  def create_subscription(user_options = {})
    options = {
      payment_method_token: cc_token,
      plan_id: 'my_plan_id'
    }.merge(user_options)

    Braintree::Subscription.create(options)
  end
end
