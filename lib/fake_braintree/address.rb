require 'fake_braintree/helpers'

module FakeBraintree
  class Address
    include Helpers

    def initialize(address_hash_from_params, options)
      set_up_address(address_hash_from_params, options)
    end

    def create
      @address['id'] = generate_id
      FakeBraintree.registry.addresses[id] = @address
      customer['addresses'] << @address
      response_for_updated_address
    end

    def customer
      FakeBraintree.registry.customers[@address['customer_id']]
    end

    def response_for_updated_address
      gzipped_response(200, @address.to_xml(root: 'address'))
    end

    def set_up_address(address_hash_from_params, options)
      @address = {
        "merchant_id" => options[:merchant_id],
        "customer_id" => options[:customer_id],
      }.merge(address_hash_from_params)
    end

    def generate_id
      "#{@address['customer_id']}_#{customer['addresses'].size}"
    end

    def id
      @address['id']
    end
  end
end
