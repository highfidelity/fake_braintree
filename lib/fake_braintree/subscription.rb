module FakeBraintree
  class Subscription
    include Helpers

    def initialize(subscription_hash, options)
      @subscription_hash = subscription_hash.merge("merchant_id" => options[:merchant_id],
                                                   "id" => options[:id])
    end

    def create
      hash = subscription_hash
      FakeBraintree.registry.subscriptions[hash["id"]] = hash
      gzipped_response(201, hash.to_xml(:root => 'subscription'))
    end

    def update
      if existing_subscription_hash
        hash = update_existing_subscription!
        gzipped_response(200, hash.to_xml(:root => 'subscription'))
      end
    end

    def subscription_hash
      subscription_hash = @subscription_hash.dup
      subscription_hash["id"]                   ||= subscription_id
      subscription_hash["transactions"]         = []
      subscription_hash["add_ons"]              = added_add_ons
      subscription_hash["discounts"]            = added_discounts
      subscription_hash["plan_id"]              = @subscription_hash["plan_id"]
      subscription_hash["next_billing_date"]    = braintree_formatted_date(1.month.from_now)
      subscription_hash["payment_method_token"] = @subscription_hash["payment_method_token"]
      subscription_hash["status"]               ||= Braintree::Subscription::Status::Active

      subscription_hash
    end

    private

    def existing_subscription_hash
      @subscription_hash['id'] && FakeBraintree.registry.subscriptions[@subscription_hash["id"]]
    end

    def update_existing_subscription!
      new_hash = existing_subscription_hash.merge(subscription_hash)
      FakeBraintree.registry.subscriptions[@subscription_hash['id']] = new_hash
    end

    def braintree_formatted_date(date)
      date.strftime('%Y-%m-%d')
    end

    def subscription_id
      md5("#{@subscription_hash["payment_method_token"]}#{Time.now.to_f}")[0,6]
    end

    def added_add_ons
      if @subscription_hash["add_ons"] && @subscription_hash["add_ons"]["add"]
        @subscription_hash["add_ons"]["add"].map { |add_on| { "id" => add_on["inherited_from_id"] } }
      else
        []
      end
    end

    def added_discounts
      if @subscription_hash["discounts"] && @subscription_hash["discounts"]["add"]
        @subscription_hash["discounts"]["add"].map { |discount| { "id" => discount["inherited_from_id"] } }
      else
        []
      end
    end
  end
end
