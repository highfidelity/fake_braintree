module FakeBraintree
  class Redirect
    include Helpers

    attr_reader :id

    def initialize(params, merchant_id)
      hash, query = *params[:tr_data].split("|", 2)
      @transparent_data = Rack::Utils.parse_query(query)
      @merchant_id = merchant_id
      @id = create_id(@merchant_id)
      @params = params
    end

    def url
      uri.to_s
    end

    def confirm
      Customer.new(@params["customer"], {:merchant_id => @merchant_id}).create
    end

    private

    def uri
      uri = URI.parse(@transparent_data["redirect_url"])
      merged_query = [uri.query, base_query].compact.join("&")
      uri.query = "#{merged_query}&hash=#{hash(merged_query)}"
      uri
    end

    def base_query
      "http_status=200&id=#{@id}&kind=create_customer"
    end

    def hash(string)
      Braintree::Digest.hexdigest(Braintree::Configuration.private_key, string)
    end
  end
end
