module SubscriptionHelpers
  def create_subscription(options = {})
    Braintree::Subscription.create({
      payment_method_token: cc_token,
      plan_id: 'my_plan_id'
    }.merge(options))
  end
end
