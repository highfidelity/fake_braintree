module FakeBraintree
  class Subscription
    include Helpers

    def initialize(request)
      @subscription_hash = Hash.from_xml(request.body).delete("subscription")
    end

    def response_hash
      response_hash = {}
      response_hash["id"]                = md5("#{@subscription_hash["payment_method_token"]}#{Time.now.to_f}")[0,6]
      response_hash["transactions"]      = []
      response_hash["add_ons"]           = []
      response_hash["discounts"]         = []
      response_hash["next_billing_date"] = 1.month.from_now
      response_hash["status"]            = Braintree::Subscription::Status::Active

      response_hash
    end
  end
end
