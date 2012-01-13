module FakeBraintree
  class Customer
    include Helpers

    def initialize(customer_hash_from_params, options)
      @customer_hash = {
        "id"          => options[:id],
        "merchant_id" => options[:merchant_id]
      }.merge(customer_hash_from_params)
    end

    def create
      if invalid?
        response_for_invalid_card
      else
        hash         = customer_hash
        credit_cards = hash["credit_cards"]
        create_customer_with(hash)
        credit_cards.each { |card| add_credit_card_to_registry(card) }
        response_for_created_customer(hash)
      end
    end

    def update
      if customer_exists_in_registry?
        updates = customer_hash
        hash = update_customer!(updates)
        response_for_updated_customer(hash)
      else
        response_for_customer_not_found
      end
    end

    def delete
      delete_customer_with_id(customer_id)
      deletion_response
    end

    private

    def customer_hash
      hash = @customer_hash.dup
      hash["id"] ||= create_id

      if hash["credit_card"] && hash["credit_card"].is_a?(Hash)
        if !hash["credit_card"].empty?
          hash["credit_card"]["last_4"] = last_four(hash)
          hash["credit_card"]["token"]  = credit_card_token(hash)

          if credit_card_expiration_month
            hash["credit_card"]["expiration_month"] = credit_card_expiration_month
          end

          if credit_card_expiration_year
            hash["credit_card"]["expiration_year"] = credit_card_expiration_year
          end

          credit_card = hash.delete("credit_card")
          hash["credit_cards"] = [credit_card]
        end
      else
        hash["credit_cards"] = []
      end

      hash
    end

    def invalid?
      credit_card_is_failure? || invalid_credit_card?
    end

    def update_customer!(hash)
      customer_from_registry.merge!(hash)
    end

    def customer_exists_in_registry?
      FakeBraintree.registry.customers.key?(customer_id)
    end

    def customer_from_registry
      FakeBraintree.registry.customers[customer_id]
    end

    def credit_card_is_failure?
      has_credit_card? && FakeBraintree.failure?(credit_card_hash["number"])
    end

    def invalid_credit_card?
      verify_credit_card?(@customer_hash) && has_invalid_credit_card?(@customer_hash)
    end

    def verify_credit_card?(customer_hash_for_verification)
      return true if FakeBraintree.verify_all_cards

      credit_card_hash_for_verification = customer_hash_for_verification["credit_card"]
      if credit_card_hash_for_verification.is_a?(Hash) &&
          credit_card_hash_for_verification.key?("options")
        options = credit_card_hash_for_verification["options"]
        options["verify_card"] == true
      end
    end

    def has_invalid_credit_card?(customer_hash)
      credit_card_number &&
        ! FakeBraintree::VALID_CREDIT_CARDS.include?(credit_card_number)
    end

    def credit_card_number
      credit_card_hash["number"]
    end

    def create_customer_with(hash)
      FakeBraintree.registry.customers[hash["id"]] = hash
    end

    def add_credit_card_to_registry(new_credit_card_hash)
      token = new_credit_card_hash["token"]
      FakeBraintree.registry.credit_cards[token] = new_credit_card_hash
    end

    def credit_card_expiration_month
      credit_card_expiration_date[0]
    end

    def credit_card_expiration_year
      credit_card_expiration_date[1]
    end

    def credit_card_expiration_date
      if credit_card_hash.key?("expiration_date")
        credit_card_hash["expiration_date"].split('/')
      else
        []
      end
    end

    def delete_customer_with_id(id)
      FakeBraintree.registry.customers[id] = nil
    end

    def deletion_response
      gzipped_response(200, '')
    end

    def response_for_created_customer(hash)
      gzipped_response(201, hash.to_xml(:root => 'customer'))
    end

    def response_for_updated_customer(hash)
      gzipped_response(200, hash.to_xml(:root => 'customer'))
    end

    def response_for_invalid_card
      failure_response(422)
    end

    def response_for_customer_not_found
      failure_response(404)
    end

    def failure_response(code)
      gzipped_response(code, FakeBraintree.failure_response(credit_card_number).to_xml(:root => 'api_error_response'))
    end

    def customer_id
      @customer_hash["id"]
    end

    def has_credit_card?
      credit_card_hash.present?
    end

    def credit_card_hash
      @customer_hash["credit_card"] || {}
    end

    def credit_card_token(hash)
      md5("#{hash['merchant_id']}#{hash['id']}")
    end

    def last_four(hash)
      hash["credit_card"].delete("number")[-4..-1]
    end

  end
end
