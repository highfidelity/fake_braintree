module FakeBraintree
  class Customer
    include Helpers

    def initialize(request, merchant_id)
      @request_hash = Hash.from_xml(request.body).delete("customer")
      @merchant_id  = merchant_id
    end

    def invalid?
      credit_card_is_failure? || invalid_credit_card?
    end

    def failure_response
      gzipped_response(422, FakeBraintree.failure_response(@request_hash["credit_card"]["number"]).to_xml(:root => 'api_error_response'))
    end

    def customer_hash
      hash = @request_hash.dup
      hash["id"] ||= create_id
      hash["merchant-id"] = @merchant_id
      if hash["credit_card"] && hash["credit_card"].is_a?(Hash)
        hash["credit_card"].delete("__content__")
        if !hash["credit_card"].empty?
          hash["credit_card"]["last_4"]           = hash["credit_card"].delete("number")[-4..-1]
          hash["credit_card"]["token"]            = md5("#{hash['merchant_id']}#{hash['id']}")
          expiration_date = hash["credit_card"].delete("expiration_date")
          hash["credit_card"]["expiration_month"] = expiration_date.split('/')[0]
          hash["credit_card"]["expiration_year"]  = expiration_date.split('/')[1]

          credit_card = hash.delete("credit_card")
          hash["credit_cards"] = [credit_card]
        end
      end

      hash
    end

    private

    def create_id
      md5("#{@merchant_id}#{Time.now.to_f}")
    end

    def credit_card_is_failure?
      FakeBraintree.failure?(@request_hash["credit_card"]["number"])
    end

    def invalid_credit_card?
      verify_credit_card?(@request_hash) && has_invalid_credit_card?(@request_hash)
    end

    def verify_credit_card?(customer_hash)
      return true if FakeBraintree.verify_all_cards

      @request_hash["credit_card"].key?("options") &&
        @request_hash["credit_card"]["options"].is_a?(Hash) &&
        @request_hash["credit_card"]["options"]["verify_card"] == true
    end

    def has_invalid_credit_card?(customer_hash)
      ! FakeBraintree::VALID_CREDIT_CARDS.include?(@request_hash["credit_card"]["number"])
    end
  end
end
