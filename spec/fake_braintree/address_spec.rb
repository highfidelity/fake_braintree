require 'spec_helper'

describe "Braintree::Address.create" do
  it "successfully creates address with valid data" do
    result = create_customer
    result = Braintree::Address.create(customer_id: result.customer.id, postal_code: 30339)
    expect(result).to be_success
  end
end
