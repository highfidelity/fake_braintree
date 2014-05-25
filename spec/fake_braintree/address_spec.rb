require 'spec_helper'

describe "Braintree::Address.create" do
  it "successfully creates address with valid data" do
    customer_response = create_customer

    address_response = Braintree::Address.create(
      customer_id: customer_response.customer.id,
      postal_code: 30339
    )

    expect(address_response).to be_success
  end
end
