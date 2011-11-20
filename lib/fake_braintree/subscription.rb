module FakeBraintree
  class Subscription
    include Helpers

    def initialize(subscription_hash, options)
      @subscription_hash = subscription_hash.merge("merchant_id" => options[:merchant_id],
                                                   "id" => options[:id])
    end

    def create
      hash = subscription_hash
      FakeBraintree.subscriptions[hash["id"]] = hash
      gzipped_response(201, hash.to_xml(:root => 'subscription'))
    end

    def subscription_hash
      subscription_hash = @subscription_hash.dup
      subscription_hash["id"]                   ||= subscription_id
      subscription_hash["transactions"]         = []
      subscription_hash["add_ons"]              = []
      subscription_hash["discounts"]            = []
      subscription_hash["plan_id"]              = @subscription_hash["plan_id"]
      subscription_hash["next_billing_date"]    = braintree_formatted_date(1.month.from_now)
      subscription_hash["payment_method_token"] = @subscription_hash["payment_method_token"]
      subscription_hash["status"]               = Braintree::Subscription::Status::Active

      subscription_hash
    end

    private

    def braintree_formatted_date(date)
      date.strftime('%Y-%m-%d')
    end

    def subscription_id
      md5("#{@subscription_hash["payment_method_token"]}#{Time.now.to_f}")[0,6]
    end
  end
end
