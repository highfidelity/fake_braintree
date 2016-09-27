require 'spec_helper'

describe "Braintree::Address.create" do
  let(:customer) { create_customer.customer }

  it "successfully creates address with valid data" do
    address_response = Braintree::Address.create(
      customer_id: customer.id,
      postal_code: 30339
    )

    expect(address_response).to be_success
  end

  it "sets the creation time" do
    address = Braintree::Address.create(customer_id: customer.id).address

    creation_time = Time.parse(address.created_at)
    expect(creation_time).to be_within(1).of(Time.now)
  end
end
