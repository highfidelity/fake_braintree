module FakeBraintree
  class MerchantAccount
    include Helpers

    def initialize(merchant_account_hash_from_params, options)
      @merchant_account_hash = {
        'id' => options[:id]
      }
      @merchant_account_hash.merge!(merchant_account_hash_from_params)
      set_merchant_account_id
    end

    def create
      if invalid?
        response_for_invalid_merchant_account
      else
        # credit_cards = customer_hash['credit_cards']
        create_merchant_account_with(merchant_account_hash)
        # credit_cards.each { |card| add_credit_card_to_registry(card) }
        # set_default_credit_card credit_cards.first
        response_for_created_merchant_account(merchant_account_hash)
      end
    end

    def update
      if merchant_account_exists_in_registry?
        updates = merchant_account_hash
        updated_merchant_account = update_existing_merchant_account(updates)
        response_for_updated_merchant_account(updated_merchant_account)
      else
        response_for_merchant_account_not_found
      end
    end

    def delete
      delete_merchant_account_with_id(merchant_account_id)
      deletion_response
    end

    private

    def invalid?
      false
    end

    def create_merchant_account_with(hash)
      FakeBraintree.registry.merchant_accounts[hash['id'].to_s] = hash
    end

    def update_existing_merchant_account(updates_hash)
      merchant_account_from_registry.merge!(updates_hash)
    end

    def merchant_account_hash
      @merchant_account_hash
    end

    def merchant_account_from_registry
      FakeBraintree.registry.merchant_accounts[merchant_account_id]
    end

    def merchant_account_exists_in_registry?
      FakeBraintree.registry.merchant_accounts.key?(merchant_account_id)
    end

    def delete_merchant_account_with_id(id)
      FakeBraintree.registry.merchant_accounts[id] = nil
    end

    def deletion_response
      gzipped_response(200, '')
    end

    def response_for_created_merchant_account(hash)
      gzipped_response(201, hash.to_xml(root: 'merchant_account'))
    end

    def response_for_updated_merchant_account(hash)
      gzipped_response(200, hash.to_xml(root: 'merchant_account'))
    end

    def response_for_merchant_account_not_found
      failure_response(404)
    end

    def failure_response(code)
      gzipped_response(code, '')
    end

    def merchant_account_id
      merchant_account_hash['id']
    end

    def set_merchant_account_id
      @merchant_account_hash['id'] ||= create_id(@merchant_account_hash['merchant_id'])
    end
  end
end
