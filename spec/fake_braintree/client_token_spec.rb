require 'spec_helper'

describe "Braintree::ClientToken.generate" do
  it "works" do
    token = Braintree::ClientToken.generate

    token = Base64.strict_decode64(token)
    expect(JSON.parse token).to eq("clientApiUrl" => "http://localhost:#{ENV['GATEWAY_PORT']}/merchants/xxx/client_api",
                        "authUrl" => "TODO_for_venmo_support",
                        "configUrl"=>"http://localhost:#{ENV['GATEWAY_PORT']}/merchants/xxx/client_api/v1/configuration",
                        "merchant_id"=>"xxx",
                        "authorizationFingerprint"=>"xxx")
  end
end
