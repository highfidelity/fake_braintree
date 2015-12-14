require 'fake_braintree/helpers'
require 'fake_braintree/valid_credit_cards'

module FakeBraintree
  class CreditCard
    include Helpers

    def initialize(credit_card_hash_from_params, options)
      set_up_credit_card(credit_card_hash_from_params, options)
      set_billing_address
      set_bin
      set_card_type
      set_expiration_month_and_year
      set_last_4
      set_unique_number_identifier
    end

    def create
      if valid_number?
        if token.nil?
          @credit_card['token'] = generate_token
        end
        @credit_card['created_at'] = Time.now
        FakeBraintree.registry.credit_cards[token] = @credit_card
        if customer = FakeBraintree.registry.customers[@credit_card['customer_id']]
          customer['credit_cards'] << @credit_card
          update_default_card
        end
        response_for_updated_card
      else
        response_for_invalid_card
      end
    end

    def update
      if credit_card_exists_in_registry?
        update_existing_credit_card
        response_for_updated_card
      else
        response_for_card_not_found
      end
    end

    def delete
      if credit_card_exists_in_registry?
        delete_credit_card
        deletion_response
      else
        response_for_card_not_found
      end
    end

    def to_xml
      @credit_card.to_xml(root: 'credit_card')
    end

    def valid_number?
      if FakeBraintree.decline_all_cards?
        false
      elsif FakeBraintree.verify_all_cards
        FakeBraintree::VALID_CREDIT_CARDS.include?(@credit_card['number'])
      else
        true
      end
    end

    private

    def update_existing_credit_card
      @credit_card = credit_card_from_registry.merge!(@credit_card)
      update_default_card
    end

    # When updating a card that has 'default' set to true, make sure only one
    # card has the flag.
    def update_default_card
      if @credit_card['default']
        FakeBraintree.registry.customers[@credit_card['customer_id']]['credit_cards'].each do |card|
          card['default'] = false
        end
        @credit_card['default'] = true
      end
    end

    def delete_credit_card
      FakeBraintree.registry.credit_cards.delete(token)
    end

    def response_for_updated_card
      gzipped_response(200, @credit_card.to_xml(root: 'credit_card'))
    end

    def credit_card_exists_in_registry?
      FakeBraintree.registry.credit_cards.key?(token)
    end

    def credit_card_from_registry
      FakeBraintree.registry.credit_cards[token]
    end

    def response_for_card_not_found
      gzipped_response(404, FakeBraintree.failure_response.to_xml(root: 'api_error_response'))
    end

    def response_for_invalid_card
      body = FakeBraintree.failure_response.merge(
        'params' => {credit_card: @credit_card}
      ).to_xml(root: 'api_error_response')

      gzipped_response(422, body)
    end

    def deletion_response
      gzipped_response(200, '')
    end

    def expiration_month
      expiration_date_parts[0]
    end

    def expiration_year
      expiration_date_parts[1]
    end

    def set_up_credit_card(credit_card_hash_from_params, options)
      @credit_card = {
        'token' => options[:token],
        'merchant_id' => options[:merchant_id],
        'customer_id' => options[:customer_id],
        'default' => options[:make_default]
      }.merge(credit_card_hash_from_params)
    end

    def set_billing_address
      if @credit_card["billing_address_id"]
        @credit_card["billing_address"] = FakeBraintree.registry.addresses[@credit_card['billing_address_id']]
      end
    end

    def set_bin
      @credit_card['bin'] = number[0, 6]
    end

    def set_card_type
      @credit_card['card_type'] = 'FakeBraintree'
    end

    def set_expiration_month_and_year
      if expiration_month
        @credit_card['expiration_month'] = expiration_month
      end

      if expiration_year
        @credit_card['expiration_year'] = expiration_year
      end
    end

    def set_last_4
      @credit_card['last_4'] = number[-4, 4]
    end

    def number
      @credit_card['number'].to_s
    end

    def set_unique_number_identifier
      @credit_card["unique_number_identifier"] = number
    end

    def generate_token
      md5("#{@credit_card['number']}#{@credit_card['merchant_id']}")
    end

    def token
      @credit_card['token']
    end

    def expiration_date_parts
      if @credit_card.key?('expiration_date')
        @credit_card['expiration_date'].split('/')
      else
        []
      end
    end
  end
end
