module FakeBraintree
  class ClientToken
    def self.generate(options = {})
      root_url = "http://localhost:#{ENV['GATEWAY_PORT']}"
      unencoded_client_token = {
        clientApiUrl: "#{root_url}/merchants/merchant_id/client_api",
        authUrl: 'http://auth.venmo.dev:9292',
        assetsUrl: "#{root_url}",
        authorizationFingerprint: options['customer_id']
      }.to_json
      Base64.encode64(unencoded_client_token)
    end
  end
end
