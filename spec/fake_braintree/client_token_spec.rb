require 'spec_helper'

describe "Braintree::ClientToken.generate" do
  it "works" do
    token = Braintree::ClientToken.generate

    expect(token).to eq "client_token"
  end
end
