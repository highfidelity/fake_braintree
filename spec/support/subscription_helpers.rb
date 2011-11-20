module SubscriptionHelpers
  def create_subscription
    Braintree::Subscription.create(:payment_method_token => cc_token,
                                   :plan_id => 'my_plan_id')
  end
end
