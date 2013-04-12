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
      case @kind
        when 'create_customer'
          Customer.new(@params['customer'], {:merchant_id => @merchant_id}).create
        when 'create_payment_method'
          credit_card_options = {:merchant_id => @merchant_id}
          credit_card_options.merge!(@transparent_data['credit_card'].fetch('options', {}))
  
          credit_card_options.symbolize_keys!
          CreditCard.new(@params['credit_card'].merge(@transparent_data['credit_card']), credit_card_options).create
        else
          raise "'#{@kind}' is currently not supported."
      end
    end

    private

    def uri
      uri = URI.parse(@transparent_data['redirect_url'])
      merged_query = [uri.query, base_query].compact.join('&')
      uri.query = "#{merged_query}&hash=#{hash(merged_query)}"
      uri
    end

    def base_query
      "http_status=200&id=#{@id}&kind=#{@kind}"
    end

    def hash(string)
      Braintree::Digest.hexdigest(Braintree::Configuration.private_key, string)
    end
  end
end
