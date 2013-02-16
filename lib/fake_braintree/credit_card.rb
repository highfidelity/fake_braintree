module FakeBraintree
  class CreditCard
    include Helpers

    def initialize(credit_card_hash_from_params, options)
      set_up_credit_card(credit_card_hash_from_params, options)
      set_expiration_month_and_year
    end

    def create
      create_credit_card
      response_for_created_card
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
      @hash.to_xml(:root => 'credit_card')
    end

    private

    def create_credit_card
      FakeBraintree.registry.credit_cards[@hash[:token]] = @hash
    end

    def update_existing_credit_card
      @hash = credit_card_from_registry.merge!(@hash)
    end

    def response_for_created_card
      gzipped_response(200, @hash.to_xml(:root => 'credit_card'))
    end

    def response_for_updated_card
      gzipped_response(200, @hash.to_xml(:root => 'credit_card'))
    end

    def credit_card_exists_in_registry?
      FakeBraintree.registry.credit_cards.key?(token)
    end

    def credit_card_from_registry
      FakeBraintree.registry.credit_cards[token]
    end

    def response_for_card_not_found
      gzipped_response(404, FakeBraintree.failure_response.to_xml(:root => 'api_error_response'))
    end

    def expiration_month
      expiration_date_parts[0]
    end

    def expiration_year
      expiration_date_parts[1]
    end

    def set_up_credit_card(credit_card_hash_from_params, options)
      @hash = {
        "token"       => options[:token],
        "merchant_id" => options[:merchant_id]
      }.merge(credit_card_hash_from_params)
    end

    def set_expiration_month_and_year
      if expiration_month
        @hash["expiration_month"] = expiration_month
      end

      if expiration_year
        @hash["expiration_year"] = expiration_year
      end
    end

    def token
      @hash['token']
    end

    def expiration_date_parts
      if @hash.key?("expiration_date")
        @hash["expiration_date"].split('/')
      else
        []
      end
    end
  end
end
