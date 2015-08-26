require 'fake_braintree/helpers'
require 'fake_braintree/credit_card'
require 'fake_braintree/valid_credit_cards'

module FakeBraintree
  class Customer
    include Helpers

    def initialize(customer_hash_from_params, options)
      @customer_hash = {
        'id' => options[:id],
        'merchant_id' => options[:merchant_id],
        'addresses' => []
      }
      @customer_hash.merge!(customer_hash_from_params)
      set_customer_id
    end

    def create
      if invalid?
        response_for_invalid_card
      else
        load_payment_method!(
          @customer_hash.delete('payment_method_nonce'),
          @customer_hash['credit_card'] ||= {}
        )
        credit_cards = customer_hash['credit_cards']
        create_customer_with(customer_hash)
        credit_cards.each { |card| add_credit_card_to_registry(card) }
        set_default_credit_card credit_cards.first
        response_for_created_customer(customer_hash)
      end
    end

    def update
      if customer_exists_in_registry?
        if credit_card_is_failure?
          response_for_invalid_card
        else
          updates = customer_hash
          updated_customer = update_existing_customer(updates)
          response_for_updated_customer(updated_customer)
        end
      else
        response_for_customer_not_found
      end
    end

    def delete
      if customer_exists_in_registry?
        delete_customer_with_id(customer_id)
        deletion_response
      else
        response_for_customer_not_found
      end
    end

    private

    def invalid?
      credit_card_is_failure? || invalid_credit_card?
    end

    def create_customer_with(hash)
      FakeBraintree.registry.customers[hash['id'].to_s] = hash
    end

    def add_credit_card_to_registry(new_credit_card_hash)
      token = new_credit_card_hash['token']
      FakeBraintree.registry.credit_cards[token] = new_credit_card_hash
    end

    def update_existing_customer(updates_hash)
      customer_from_registry.merge!(updates_hash)
    end

    def customer_hash
      @customer_hash.merge('credit_cards' => generate_credit_cards_from(@customer_hash['credit_card']))
    end

    def customer_from_registry
      FakeBraintree.registry.customers[customer_id]
    end

    def customer_exists_in_registry?
      FakeBraintree.registry.customers.key?(customer_id)
    end

    def credit_card_is_failure?
      has_credit_card? && FakeBraintree.failure?(credit_card_number)
    end

    def invalid_credit_card?
      verify_credit_card?(customer_hash) && has_invalid_credit_card?(customer_hash)
    end

    def verify_credit_card?(customer_hash_for_verification)
      return true if FakeBraintree.verify_all_cards

      credit_card_hash_for_verification = customer_hash_for_verification['credit_card']
      if credit_card_hash_for_verification.is_a?(Hash) &&
          credit_card_hash_for_verification.key?('options')
        options = credit_card_hash_for_verification['options']
        options['verify_card'] == true
      end
    end

    def has_invalid_credit_card?(customer_hash)
      credit_card_number &&
        ! FakeBraintree::VALID_CREDIT_CARDS.include?(credit_card_number)
    end

    def credit_card_number
      credit_card_hash['number']
    end

    def set_default_credit_card(credit_card_hash)
      if credit_card_hash
        CreditCard.new(credit_card_hash, customer_id: @customer_hash['id'], make_default: true).update
      end
    end

    def generate_credit_cards_from(new_credit_card_hash)
      if new_credit_card_hash.present? && new_credit_card_hash.is_a?(Hash)
        load_payment_method!(
          new_credit_card_hash.delete('payment_method_nonce'),
          new_credit_card_hash
        )

        new_credit_card_hash['bin'] = new_credit_card_hash['number'][0..5]
        new_credit_card_hash['last_4'] = new_credit_card_hash['number'][-4..-1]
        new_credit_card_hash['token']  = credit_card_token(new_credit_card_hash)

        if credit_card_expiration_month
          new_credit_card_hash['expiration_month'] = credit_card_expiration_month
        end

        if credit_card_expiration_year
          new_credit_card_hash['expiration_year'] = credit_card_expiration_year
        end

        [new_credit_card_hash]
      else
        []
      end
    end

    def credit_card_expiration_month
      credit_card_expiration_date[0]
    end

    def credit_card_expiration_year
      credit_card_expiration_date[1]
    end

    def credit_card_expiration_date
      if credit_card_hash.key?('expiration_date')
        credit_card_hash['expiration_date'].split('/')
      else
        []
      end
    end

    def delete_customer_with_id(id)
      FakeBraintree.registry.customers.delete(id)
    end

    def deletion_response
      gzipped_response(200, '')
    end

    def response_for_created_customer(hash)
      gzipped_response(201, hash.to_xml(root: 'customer'))
    end

    def response_for_updated_customer(hash)
      gzipped_response(200, hash.to_xml(root: 'customer'))
    end

    def response_for_invalid_card
      failure_response(422)
    end

    def response_for_customer_not_found
      failure_response(404)
    end

    def failure_response(code)
      gzipped_response(code, FakeBraintree.failure_response(credit_card_number).to_xml(root: 'api_error_response'))
    end

    def customer_id
      customer_hash['id']
    end

    def has_credit_card?
      credit_card_hash.present?
    end

    def credit_card_hash
      @customer_hash['credit_card'] || {}
    end

    def set_customer_id
      @customer_hash['id'] ||= create_id(@customer_hash['merchant_id'])
    end

    def credit_card_token(credit_card_hash_without_token)
      md5("#{credit_card_hash_without_token['number']}#{@customer_hash['merchant_id']}")
    end

    def load_payment_method!(nonce, credit_card_hash)
      return unless nonce
      payment_method_hash = FakeBraintree.registry.payment_methods[nonce]
      credit_card_hash.merge!(payment_method_hash)
    end
  end
end
