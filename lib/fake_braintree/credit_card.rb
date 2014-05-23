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
          @hash['token'] = generate_token
        end
        FakeBraintree.registry.credit_cards[token] = @hash
        if customer = FakeBraintree.registry.customers[@hash['customer_id']]
          customer['credit_cards'] << @hash
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

    def to_xml
      @hash.to_xml(root: 'credit_card')
    end

    def valid_number?
      if FakeBraintree.decline_all_cards?
        false
      elsif FakeBraintree.verify_all_cards
        FakeBraintree::VALID_CREDIT_CARDS.include?(@hash['number'])
      else
        true
      end
    end

    private

    def update_existing_credit_card
      @hash = credit_card_from_registry.merge!(@hash)
      update_default_card
    end

    # When updating a card that has 'default' set to true, make sure
    # only one card has the flag.
    def update_default_card
      if @hash['default']
        FakeBraintree.registry.customers[@hash['customer_id']]['credit_cards'].each do |card|
          card['default'] = false
        end
        @hash['default'] = true
      end
    end

    def response_for_updated_card
      gzipped_response(200, @hash.to_xml(root: 'credit_card'))
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
      gzipped_response(422, FakeBraintree.failure_response.merge(
          'params' => {credit_card: @hash}
        ).
        to_xml(root: 'api_error_response'))
    end

    def expiration_month
      expiration_date_parts[0]
    end

    def expiration_year
      expiration_date_parts[1]
    end

    def set_up_credit_card(credit_card_hash_from_params, options)
      @hash = {
        'token' => options[:token],
        'merchant_id' => options[:merchant_id],
        'customer_id' => options[:customer_id],
        'default' => options[:make_default]
      }.merge(credit_card_hash_from_params)
    end

    def set_billing_address
      if @hash["billing_address_id"]
        @hash["billing_address"] = FakeBraintree.registry.addresses[@hash['billing_address_id']]
      end
    end

    def set_bin
      @hash['bin'] = number[0, 6]
    end

    def set_card_type
      @hash['card_type'] = 'FakeBraintree'
    end

    def set_expiration_month_and_year
      if expiration_month
        @hash['expiration_month'] = expiration_month
      end

      if expiration_year
        @hash['expiration_year'] = expiration_year
      end
    end

    def set_last_4
      @hash['last_4'] = number[-4, 4]
    end

    def number
      @hash['number'].to_s
    end    

    def set_unique_number_identifier
      @hash["unique_number_identifier"] = number
    end    

    def generate_token
      md5("#{@hash['number']}#{@hash['merchant_id']}")
    end

    def token
      @hash['token']
    end

    def expiration_date_parts
      if @hash.key?('expiration_date')
        @hash['expiration_date'].split('/')
      else
        []
      end
    end
  end
end
