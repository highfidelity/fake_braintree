module FakeBraintree
  class Customer
    include Helpers

    def initialize(customer_hash, merchant_id)
      @customer_hash = customer_hash
      @merchant_id  = merchant_id
    end

    def create
      if invalid?
        failure_response
      else
        hash = customer_hash
        FakeBraintree.customers[hash["id"]] = hash
        gzipped_response(201, hash.to_xml(:root => 'customer'))
      end
    end

    def customer_hash
      hash = @customer_hash.dup
      hash["id"] ||= create_id
      hash["merchant-id"] = @merchant_id

      if hash["credit_card"] && hash["credit_card"].is_a?(Hash)
        if !hash["credit_card"].empty?
          hash["credit_card"]["last_4"] = last_four(hash)
          hash["credit_card"]["token"]  = credit_card_token(hash)
          split_expiration_date_into_month_and_year!(hash)

          credit_card = hash.delete("credit_card")
          hash["credit_cards"] = [credit_card]
        end
      end

      hash
    end

    private

    def invalid?
      credit_card_is_failure? || invalid_credit_card?
    end

    def split_expiration_date_into_month_and_year!(hash)
      if expiration_date = hash["credit_card"].delete("expiration_date")
        hash["credit_card"]["expiration_month"] = expiration_date.split('/')[0]
        hash["credit_card"]["expiration_year"]  = expiration_date.split('/')[1]
      end
    end

    def credit_card_token(hash)
      md5("#{hash['merchant_id']}#{hash['id']}")
    end

    def last_four(hash)
      hash["credit_card"].delete("number")[-4..-1]
    end

    def failure_response
      gzipped_response(422, FakeBraintree.failure_response(@customer_hash["credit_card"]["number"]).to_xml(:root => 'api_error_response'))
    end

    def credit_card_is_failure?
      @customer_hash.key?('credit_card') &&
        FakeBraintree.failure?(@customer_hash["credit_card"]["number"])
    end

    def invalid_credit_card?
      verify_credit_card?(@customer_hash) && has_invalid_credit_card?(@customer_hash)
    end

    def verify_credit_card?(customer_hash)
      return true if FakeBraintree.verify_all_cards

      @customer_hash.key?("credit_card") &&
        @customer_hash["credit_card"].is_a?(Hash) &&
        @customer_hash["credit_card"].key?("options") &&
        @customer_hash["credit_card"]["options"].is_a?(Hash) &&
        @customer_hash["credit_card"]["options"]["verify_card"] == true
    end

    def has_invalid_credit_card?(customer_hash)
      has_credit_card_number? &&
        ! FakeBraintree::VALID_CREDIT_CARDS.include?(@customer_hash["credit_card"]["number"])
    end

    def has_credit_card_number?
      @customer_hash.key?("credit_card") &&
        @customer_hash["credit_card"].is_a?(Hash) &&
        @customer_hash["credit_card"].key?("number")
    end
  end
end
