module FakeBraintree
  class CreditCard
    include Helpers

    def initialize(credit_card_hash, options)
      set_up_credit_card(credit_card_hash, options)
      set_expiration_month_and_year
    end

    def update
      if credit_card_exists_in_registry?
        updated_credit_card = update_credit_card!
        update_response_for(updated_credit_card)
      else
        credit_card_not_found_response
      end
    end

    private

    def credit_card
      @credit_card.dup
    end

    def update_credit_card!
      credit_card_from_registry.merge!(credit_card)
    end

    def update_response_for(credit_card)
      gzipped_response(200, credit_card.to_xml(:root => 'credit_card'))
    end

    def credit_card_exists_in_registry?
      token = credit_card['token']
      FakeBraintree.registry.credit_cards.key?(token)
    end

    def credit_card_from_registry
      token = credit_card['token']
      FakeBraintree.registry.credit_cards[token]
    end

    def credit_card_not_found_response
      gzipped_response(404, FakeBraintree.failure_response.to_xml(:root => 'api_error_response'))
    end

    def expiration_month
      if credit_card.key?("expiration_date")
        credit_card["expiration_date"].split('/')[0]
      end
    end

    def expiration_year
      if credit_card.key?("expiration_date")
        credit_card["expiration_date"].split('/')[1]
      end
    end

    def set_up_credit_card(credit_card_hash, options)
      @credit_card = {
        "token"       => options[:token],
        "merchant_id" => options[:merchant_id]
      }.merge(credit_card_hash)
    end

    def set_expiration_month_and_year
      if expiration_month
        @credit_card["expiration_month"] = expiration_month
      end
      if expiration_year
        @credit_card["expiration_year"] = expiration_year
      end
    end
  end
end
