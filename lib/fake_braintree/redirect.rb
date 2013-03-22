module FakeBraintree
  class Redirect
    include Helpers

    attr_reader :id

    def initialize(params, merchant_id)
      hash, query = *params[:tr_data].split('|', 2)
      @transparent_data = Rack::Utils.parse_nested_query(query)
      @merchant_id = merchant_id
      @id = create_id(@merchant_id)
      @params = params
      @kind = @transparent_data['kind']
    end

    def url
      uri.to_s
    end

    def confirm
      if @kind == 'create_customer'
        Customer.new(@params['customer'], {:merchant_id => @merchant_id}).create
      elsif @kind == 'create_payment_method'
        credit_card_options = {:merchant_id => @merchant_id}
        credit_card_options.merge!(@transparent_data['credit_card'].fetch('options', {}))

        credit_card_options.symbolize_keys!
        CreditCard.new(@params['credit_card'].merge(@transparent_data['credit_card']), credit_card_options).create
      end
    end

    private

    def uri
      URI.parse(@transparent_data['redirect_url']).merge("?#{base_query}&hash=#{hash(base_query)}")
    end

    def base_query
      "http_status=200&id=#{@id}&kind=#{@kind}"
    end

    def hash(string)
      Braintree::Digest.hexdigest(Braintree::Configuration.private_key, string)
    end
  end
end
