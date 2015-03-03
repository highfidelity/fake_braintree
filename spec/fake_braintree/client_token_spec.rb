require 'spec_helper'

describe 'Braintree::ClientToken.generate' do
  it 'includes expected encoded fields' do
    raw_client_token = Braintree::ClientToken.generate
    client_token = decode_client_token(raw_client_token)

    regex = /^http:\/\/localhost:\d+\/merchants\/[^\/]+\/client_api$/
    expect(client_token['clientApiUrl']).to match regex
    expect(client_token['authUrl']).to eq 'http://auth.venmo.dev:9292'
  end

  def decode_client_token(raw_client_token)
    decoded_client_token_string = Base64.decode64(raw_client_token)
    JSON.parse(decoded_client_token_string)
  end
end
