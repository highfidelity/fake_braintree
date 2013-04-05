module FakeBraintree
  class Address
    include Helpers

    def initialize(address_hash_from_params, options)
      set_up_address(address_hash_from_params, options)
    end

    def create
      @hash['id'] = generate_id
      FakeBraintree.registry.addresses[id] = @hash
      customer['addresses'] << @hash
      response_for_updated_address
    end

    def customer
      FakeBraintree.registry.customers[@hash['customer_id']]
    end

    def response_for_updated_address
      gzipped_response(200, @hash.to_xml(:root => 'address'))
    end

    def set_up_address(address_hash_from_params, options)
      @hash = {
        "merchant_id" => options[:merchant_id],
        "customer_id" => options[:customer_id],
      }.merge(address_hash_from_params)
    end

    def generate_id
      "#{@hash['customer_id']}_#{customer['addresses'].size}"
    end

    def id
      @hash['id']
    end
  end
end
