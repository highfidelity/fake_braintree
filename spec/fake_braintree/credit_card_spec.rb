require 'spec_helper'

describe 'Braintree::CreditCard.find' do
  it 'gets the correct credit card' do
    month = '04'
    year = '2016'
    credit_card = Braintree::CreditCard.find(token_for(month, year))

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

describe 'Braintree::CreditCard.sale' do
  it 'successfully creates a sale' do
    result = Braintree::CreditCard.sale(cc_token, amount: 10.00)

    expect(result).to be_success
    expect(Braintree::Transaction.find(result.transaction.id)).to be
  end
end

describe 'Braintree::CreditCard.create' do
  it 'allows creating a credit card without a customer' do
    result = Braintree::CreditCard.create(build_credit_card_hash)

    expect(result).to be_success
    expect(Braintree::CreditCard.find('token')).to_not be_nil
  end

  context 'with a customer' do
    before do
      @customer = Braintree::Customer.create.customer
    end

    it 'fails to create a credit card if decline_all_cards is set' do
      FakeBraintree.decline_all_cards!

      result = Braintree::CreditCard.create(build_credit_card_hash)

      expect(result).to_not be_success
      expect { Braintree::CreditCard.find('token') }.to raise_error Braintree::NotFoundError
    end

    it 'fails to create a credit card if verify_all_cards is set and card is invalid' do
      FakeBraintree.verify_all_cards!
      result = Braintree::CreditCard.create(build_credit_card_hash.merge(number: '12345'))
      expect(result).to_not be_success
      expect { Braintree::CreditCard.find('token') }.to raise_error Braintree::NotFoundError
    end

    it 'successfully creates a credit card' do
      result = Braintree::CreditCard.create(build_credit_card_hash)
      expect(result).to be_success
      expect(Braintree::Customer.find(@customer.id).credit_cards.last.token).to eq 'token'
      expect(Braintree::Customer.find(@customer.id).credit_cards.last).to be_default
      expect(Braintree::Customer.find(@customer.id).credit_cards.last.billing_address.postal_code).to eq "94110"
    end

    it 'only allows one credit card to be default' do
      result = Braintree::CreditCard.create(build_credit_card_hash)
      expect(result).to be_success
      result = Braintree::CreditCard.create(build_credit_card_hash)
      expect(result).to be_success
      # Reload the customer
      @customer = Braintree::Customer.find(@customer.id)
      expect(@customer.credit_cards.select(&:default?).length).to eq 1
      expect(@customer.credit_cards.length).to eq 2
    end

    it 'should create a credit card based on the payment method nonce' do
      result = Braintree::CreditCard.create(build_payment_method_nonce_hash)
      expect(result).to be_success
      @customer = Braintree::Customer.find(@customer.id)
      expect(@customer.credit_cards.last.last_4).to eq '1111'
      expect(@customer.credit_cards.length).to eq 1
    end
  end

  it "sets the creation time" do
    credit_card = Braintree::CreditCard.create(build_credit_card_hash).credit_card

    creation_time = Time.parse(credit_card.created_at)
    expect(creation_time).to be_within(1).of(Time.now)
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

  def build_payment_method_nonce_hash
    {
      customer_id: @customer && @customer.id,
      payment_method_nonce: 'fake-valid-nonce',
      billing_address: {
        postal_code: '94110'
      },
      options: {
        make_default: true
      }
    }
  end
end

describe 'Braintree::CreditCard.update' do
  it 'successfully updates the credit card' do
    new_expiration_date = '08/2012'
    token = cc_token

    result = Braintree::CreditCard.update(token, expiration_date: new_expiration_date)
    expect(result).to be_success
    expect(Braintree::CreditCard.find(token).expiration_date).to eq new_expiration_date
  end

  it 'raises an error for a nonexistent credit card' do
    expect { Braintree::CreditCard.update('foo', number: TEST_CC_NUMBER) }.to raise_error(Braintree::NotFoundError)
  end
end

describe 'Braintree::CreditCard.delete' do
  it 'successfully deletes a credit card' do
    token = cc_token # creates card

    result = Braintree::CreditCard.delete(token)

    expect(result).to eq true
    expect { Braintree::CreditCard.find(token) }.to raise_error(Braintree::NotFoundError)
  end

  it 'raises an error for a nonexistent credit card' do
    expect { Braintree::CreditCard.delete('foo') }.to raise_error(Braintree::NotFoundError)
  end
end
