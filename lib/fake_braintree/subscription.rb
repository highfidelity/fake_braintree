module FakeBraintree
  class Subscription
    include Helpers

    def initialize(request)
      @subscription_hash = Hash.from_xml(request.body).delete("subscription")
    end

    def response_hash
      response_hash = {}
      response_hash["id"]                   = md5("#{@subscription_hash["payment_method_token"]}#{Time.now.to_f}")[0,6]
      response_hash["transactions"]         = []
      response_hash["add_ons"]              = []
      response_hash["discounts"]            = []
      response_hash["plan_id"]              = @subscription_hash["plan_id"]
      response_hash["next_billing_date"]    = braintree_formatted_date(1.month.from_now)
      response_hash["payment_method_token"] = @subscription_hash["payment_method_token"]
      response_hash["status"]               = Braintree::Subscription::Status::Active

      response_hash
    end

    private

    def braintree_formatted_date(date)
      date.strftime('%Y-%m-%d')
    end
  end
end
