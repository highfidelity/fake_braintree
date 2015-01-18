require 'spec_helper'

describe 'Braintree::PaymentMethod.find' do
  it 'gets the correct credit card' do
    month = '04'
    year = '2016'
    credit_card = Braintree::PaymentMethod.find(token_for(month, year))

    expect(credit_card.bin).to eq TEST_CC_NUMBER[0, 6]
    expect(credit_card.card_type).to eq "FakeBraintree"
    expect(credit_card.last_4).to eq TEST_CC_NUMBER[-4,4]
    expect(credit_card.expiration_month).to eq month
    expect(credit_card.expiration_year).to eq  year
    expect(credit_card.unique_number_identifier).to eq TEST_CC_NUMBER
  end

  def token_for(month, year)
    braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/'))
  end
end

describe 'Braintree::PaymentMethod.update' do
  it 'successfully updates the credit card' do
    new_expiration_date = '08/2012'
    token = cc_token

    result = Braintree::PaymentMethod.update(token, expiration_date: new_expiration_date)
    expect(result).to be_success
    expect(Braintree::CreditCard.find(token).expiration_date).to eq new_expiration_date
  end

  it 'raises an error for a nonexistent credit card' do
    expect { Braintree::PaymentMethod.update('foo', number: TEST_CC_NUMBER) }.to raise_error(Braintree::NotFoundError)
  end
end

describe 'Braintree::PaymentMethod.create' do
  it 'allows creating a credit card without a customer' do
    nonce = FakeBraintree::PaymentMethod.tokenize_card(build_credit_card_hash)
    result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)

    expect(result).to be_success
    expect(Braintree::PaymentMethod.find('token')).to_not be_nil
  end

  context 'with a customer' do
    before do
      @customer = Braintree::Customer.create.customer
    end

    it 'fails to create a credit card if decline_all_cards is set' do
      FakeBraintree.decline_all_cards!

      nonce = FakeBraintree::PaymentMethod.tokenize_card(build_credit_card_hash)
      result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)

      expect(result).to_not be_success
      expect { Braintree::PaymentMethod.find('token') }.to raise_error Braintree::NotFoundError
    end

    it 'fails to create a credit card if verify_all_cards is set and card is invalid' do
      FakeBraintree.verify_all_cards!

      nonce = FakeBraintree::PaymentMethod.tokenize_card(build_credit_card_hash.merge(number: '12345'))
      result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)

      expect(result).to_not be_success
      expect { Braintree::CreditCard.find('token') }.to raise_error Braintree::NotFoundError
    end

    it 'successfully creates a credit card' do
      nonce = FakeBraintree::PaymentMethod.tokenize_card(build_credit_card_hash)
      result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)

      expect(result).to be_success
      expect(Braintree::Customer.find(@customer.id).credit_cards.last.token).to eq 'token'
      expect(Braintree::Customer.find(@customer.id).credit_cards.last).to be_default
      expect(Braintree::Customer.find(@customer.id).credit_cards.last.billing_address.postal_code).to eq "94110"
    end

    it 'only allows one credit card to be default' do
      nonce = FakeBraintree::PaymentMethod.tokenize_card(build_credit_card_hash)
      result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)
      expect(result).to be_success
      result = Braintree::PaymentMethod.create(payment_method_nonce: nonce)
      expect(result).to be_success
      # Reload the customer
      @customer = Braintree::Customer.find(@customer.id)
      expect(@customer.credit_cards.select(&:default?).length).to eq 1
      expect(@customer.credit_cards.length).to eq 2
    end
  end

  def build_credit_card_hash
    {
      customer_id: @customer && @customer.id,
      number: '4111111111111111',
      cvv: '123',
      token: 'token',
      expiration_date: '07/2020',
      billing_address: {
        postal_code: '94110'
      },
      options: {
        make_default: true
      }
    }
  end

  describe 'FakeBraintree::PaymentMethod.tokenize_card' do
  it 'stores provided payment data in the registry' do
    FakeBraintree::PaymentMethod.tokenize_card number: '4111111111111111'
    first_payment_method = FakeBraintree.registry.payment_methods.values[0]
    expect(first_payment_method['number']).to eq '4111111111111111'
  end

  it 'returns key to payment data' do
    nonce = FakeBraintree::PaymentMethod.tokenize_card number: '4111111111111111'
    payment_methods = FakeBraintree.registry.payment_methods
    expect(payment_methods[nonce]['number']).to eq '4111111111111111'
  end
end
end
