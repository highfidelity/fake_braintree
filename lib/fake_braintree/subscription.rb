require 'fake_braintree/helpers'

module FakeBraintree
  class Subscription
    include Helpers

    def initialize(subscription_hash_from_params, options)
      id = subscription_hash_from_params['id'] || options[:id]
      @subscription_hash = subscription_hash_from_params.merge(
        'merchant_id' => options[:merchant_id],
        'id' => id
      )
      set_subscription_id
      set_subscription_status
    end

    def create
      create_subscription_with(subscription_hash)
      if credit_card = FakeBraintree.registry.credit_cards[payment_method_token]
        credit_card['subscriptions'] ||= []
        credit_card['subscriptions'] << subscription_hash
      end
      response_for_created_subscription(subscription_hash)
    end

    def update
      if subscription_exists_in_registry?
        updated_subscription = update_existing_subscription(subscription_hash)
        response_for_created_subscription(updated_subscription)
      else
        response_for_subscription_not_found
      end
    end

    def cancel
      if subscription_exists_in_registry?
        canceled_subscription = update_existing_subscription('status' => canceled_status)
        response_for_canceled_subscription(canceled_subscription)
      else
        response_for_subscription_not_found
      end
    end

    private

    def subscription_hash
      @subscription_hash.merge(
        'transactions' => [],
        'add_ons' => add_ons,
        'discounts' => discounts,
        'next_billing_date' => braintree_formatted_date(next_billing_date),
        'billing_day_of_month' => billing_day_of_month,
        'billing_period_start_date' => braintree_formatted_date(billing_period_start_date),
        'billing_period_end_date' => braintree_formatted_date(billing_period_end_date)
      )
    end

    def update_existing_subscription(updates)
      updated_subscription = subscription_from_registry.merge(updates)
      FakeBraintree.registry.subscriptions[subscription_id] = updated_subscription
    end

    def create_subscription_with(new_subscription_hash)
      FakeBraintree.registry.subscriptions[new_subscription_hash['id'].to_s] = new_subscription_hash
    end

    def subscription_from_registry
      FakeBraintree.registry.subscriptions[subscription_id]
    end

    def subscription_exists_in_registry?
      FakeBraintree.registry.subscriptions.key?(subscription_id)
    end

    def braintree_formatted_date(date)
      date.strftime('%Y-%m-%d')
    end

    def add_ons
      discounts_or_add_ons(@subscription_hash['add_ons'])
    end

    def discounts
      discounts_or_add_ons(@subscription_hash['discounts'])
    end

    def discounts_or_add_ons(discount_or_add_on)
      return [] unless discount_or_add_on.is_a?(Hash)

      if discount_or_add_on['add']
        discount_or_add_on['add'].map do |hsh|
          {
            'id'       => hsh['inherited_from_id'],
            'quantity' => hsh['quantity'],
            'amount'   => hsh['amount']
          }
        end
      elsif discount_or_add_on['update']
        discount_or_add_on['update'].map do |hsh|
          {
            'id'       => hsh['existing_id'],
            'quantity' => hsh['quantity'],
            'amount'   => hsh['amount']
          }
        end
      else
        []
      end
    end

    def next_billing_date
      billing_period_start_date + 1.month
    end

    def billing_day_of_month
      next_billing_date.mday > 28 ? 31 : next_billing_date.mday
    end

    def billing_period_start_date
      @billing_period_start_date ||= Date.today
    end

    def billing_period_end_date
      next_billing_date - 1.day
    end

    def set_subscription_id
      @subscription_hash['id'] ||= generate_new_subscription_id
    end

    def set_subscription_status
      @subscription_hash['status'] ||= active_status
    end

    def subscription_id
      subscription_hash['id']
    end

    def generate_new_subscription_id
      md5("#{payment_method_token}#{Time.now.to_f}")[0,6]
    end

    def payment_method_token
      @subscription_hash['payment_method_token']
    end

    def active_status
      Braintree::Subscription::Status::Active
    end

    def canceled_status
      Braintree::Subscription::Status::Canceled
    end

    def response_for_created_subscription(hash)
      gzipped_response(201, hash.to_xml(root: 'subscription'))
    end

    def response_for_subscription_not_found
      gzipped_response(404, {})
    end

    def response_for_canceled_subscription(hash)
      gzipped_response(200, hash.to_xml(root: 'subscription'))
    end
  end
end
