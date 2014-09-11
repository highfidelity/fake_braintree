require 'spec_helper'

describe 'Braintree::Customer.create' do
  after { FakeBraintree.verify_all_cards = false }

  it 'successfully creates a customer' do
    result = Braintree::Customer.create(
      credit_card: {
        number: TEST_CC_NUMBER,
        expiration_date: '04/2016'
      }
    )
    expect(result).to be_success
  end

  it 'associates a created credit card with the customer' do
    result = Braintree::Customer.create(
      credit_card: {
        number: TEST_CC_NUMBER,
        expiration_date: '04/2016'
      }
    )
    credit_cards = Braintree::Customer.find(result.customer.id).credit_cards
    expect(credit_cards.size).to eq 1
    expect(credit_cards.first.expiration_date).to eq '04/2016'
  end

  it "successfully creates the customer's credit card" do
    result = Braintree::Customer.create(
      credit_card: {
        number: TEST_CC_NUMBER,
        expiration_date: '04/2016'
      }
    )

    cc_token = result.customer.credit_cards.first.token
    expect { Braintree::CreditCard.find(cc_token) }.not_to raise_error
  end

  it "sets a default credit card for the customer" do
    result = Braintree::Customer.create(
      credit_card: {
        number: TEST_CC_NUMBER,
        expiration_date: '04/2016'
      }
    )

    credit_cards = Braintree::Customer.find(result.customer.id).credit_cards
    expect(credit_cards.first).to be_default
  end

  it 'can handle an empty credit card hash' do
    result = Braintree::Customer.create(credit_card: {})
    expect(result).to be_success
  end

  it 'does not overwrite a passed customer id' do
    result = Braintree::Customer.create({ 'id' => '123' })

    expect(result.customer.id).to eq('123')
  end

  it 'creates a customer using an expiration month and year' do
    result = Braintree::Customer.create(
      credit_card: {
        number: TEST_CC_NUMBER,
        expiration_month: '04',
        expiration_year: '2016'
      }
    )
    expect(result).to be_success
  end

  it 'records the billing address' do
    result = create_customer(
      billing_address: {
        street_address: '1 E Main St',
        extended_address: 'Suite 3',
        locality: 'Chicago',
        region: 'Illinois',
        postal_code: '60622',
        country_code_alpha2: 'US'
      }
    )

    billing_address = result.customer.credit_cards[0].billing_address

    expect(billing_address.street_address).to eq '1 E Main St'
    expect(billing_address.postal_code).to eq '60622'
  end
end

describe 'Braintree::Customer.create', 'when passed verify_card: true' do
  it 'accepts valid cards' do
    expect(create_customer(options: { verify_card: true })).to be_success
  end

  it 'rejects invalid cards' do
    expect(create_customer_with_invalid_card(options: { verify_card: true })).to_not be_success
  end
end

describe 'Braintree::Customer.create', 'when FakeBraintree.verify_all_cards == true' do
  before { FakeBraintree.verify_all_cards! }

  it 'accepts valid cards' do
    expect(create_customer).to be_success
  end

  it 'rejects invalid cards' do
    expect(create_customer_with_invalid_card).to_not be_success
  end
end

describe 'Braintree::Customer.find' do
  it 'successfully finds a customer' do
    result = Braintree::Customer.create(
      first_name: 'Bob',
      last_name: 'Smith'
    )

    expect(Braintree::Customer.find(result.customer.id).first_name).to eq 'Bob'
  end

  it 'raises an error for a nonexistent customer' do
    expect(lambda { Braintree::Customer.find('foo') }).to raise_error(Braintree::NotFoundError)
  end

  it 'finds customer created with custom id' do
    Braintree::Customer.create(
        id: 'bob-smith',
        first_name: 'Bob',
        last_name: 'Smith'
    )

    expect(Braintree::Customer.find('bob-smith').first_name).to eq 'Bob'
  end

  it 'finds customer created with custom integer id' do
    Braintree::Customer.create(
        id: 1,
        first_name: 'Bob',
        last_name: 'Smith'
    )

    expect(Braintree::Customer.find(1).first_name).to eq 'Bob'
  end
end

describe 'Braintree::Customer.update' do
  it 'successfully updates a customer' do
    customer_id = create_customer.customer.id
    result = Braintree::Customer.update(customer_id, first_name: 'Jerry')

    expect(result).to be_success
    expect(Braintree::Customer.find(customer_id).first_name).to eq 'Jerry'
  end

  it 'raises an error for a nonexistent customer' do
    expect { Braintree::Customer.update('foo', {first_name: 'Bob'}) }.to raise_error(Braintree::NotFoundError)
  end

  it 'does not allow a customer to be updated to a failing credit card' do
    bad_credit_card = '123456'
    FakeBraintree.registry.failures[bad_credit_card] = FakeBraintree.failure_response

    customer = create_customer
    result =  Braintree::Customer.update(customer.customer.id,
      credit_card: { number: bad_credit_card }
    )
    expect(result).to_not be_success
  end
end

describe 'Braintree::Customer.delete' do
  it 'successfully deletes a customer' do
    customer_id = create_customer.customer.id
    result = Braintree::Customer.delete(customer_id)

    expect(result).to be_success
    expect { Braintree::Customer.find(customer_id) }.to raise_error(Braintree::NotFoundError)
  end
end
