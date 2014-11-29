require "spec_helper"

describe "Braintree::ClientToken.generate" do
  it "works" do
    expect(SecureRandom).to receive(:hex).and_return("a-token")

    token = Braintree::ClientToken.generate

    expect(token).to eq "a-token"
  end
end
