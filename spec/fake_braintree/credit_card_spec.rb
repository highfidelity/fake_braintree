require 'spec_helper'

describe "Braintree::CreditCard.find" do
  it "gets the correct credit card" do
    credit_card = Braintree::CreditCard.find(token)

    credit_card.last_4.should == TEST_CC_NUMBER[-4,4]
    credit_card.expiration_month.should == month
    credit_card.expiration_year.should ==  year
  end

  let(:month) { '04' }
  let(:year)  { '2016' }
  let(:token) { braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/')) }
end

describe "Braintree::CreditCard.create" do
  let(:month) { '04' }
  let(:year)  { '2016' }
  let(:token) { braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/')) }
  it "successfully creates card with valid data" do
    result = Braintree::CreditCard.create :token => token,
      :number => TEST_CC_NUMBER
    result.should be_success

    Braintree::CreditCard.find(token).should be
  end
end

describe "Braintree::CreditCard.sale" do
  it "successfully creates a sale" do
    result = Braintree::CreditCard.sale(cc_token, :amount => 10.00)
    result.should be_success
    Braintree::Transaction.find(result.transaction.id).should be
  end
end

describe "Braintree::CreditCard.create" do
  it 'fails to create a credit card without a customer' do
    result = Braintree::CreditCard.create(
      :customer_id => 'fail',
      :number => '4111111111111111',
      :cvv => '123',
      :token => 'token',
      :expiration_date => '07/2020',
      :billing_address => {
        :postal_code => '94110'
      },
      :options => {
        :make_default => true
      }
    )
    result.should_not be_success
    expect { Braintree::CreditCard.find('token') }.to raise_exception Braintree::NotFoundError
  end

  context 'with a customer' do
    before do
      @customer = Braintree::Customer.create.customer
    end
    it 'successfully creates a credit card' do
      result = Braintree::CreditCard.create(
        :customer_id => @customer.id,
        :number => '4111111111111111',
        :cvv => '123',
        :token => 'token',
        :expiration_date => '07/2020',
        :billing_address => {
          :postal_code => '94110'
        },
        :options => {
          :make_default => true
        }
      )
      result.should be_success
      Braintree::Customer.find(@customer.id).credit_cards.last.token.should == 'token'
      Braintree::Customer.find(@customer.id).credit_cards.last.default?.should be_true
    end

    it 'only allows one credit card to be default' do
      result = Braintree::CreditCard.create(
        :customer_id => @customer.id,
        :number => '4111111111111111',
        :cvv => '123',
        :token => 'token',
        :expiration_date => '07/2020',
        :billing_address => {
          :postal_code => '94110'
        },
        :options => {
          :make_default => true
        }
      )
      result.should be_success
      result = Braintree::CreditCard.create(
        :customer_id => @customer.id,
        :number => '4111111111111111',
        :cvv => '123',
        :token => 'token',
        :expiration_date => '07/2020',
        :billing_address => {
          :postal_code => '94110'
        },
        :options => {
          :make_default => true
        }
      )
      result.should be_success
      # Reload the customer
      @customer = Braintree::Customer.find(@customer.id)
      @customer.credit_cards.select {|c| c.default?}.length.should == 1
      @customer.credit_cards.length.should == 2
    end
  end
end

describe "Braintree::CreditCard.update" do
  it "successfully updates the credit card" do
    new_expiration_date = "08/2012"
    token = cc_token

    result = Braintree::CreditCard.update(token, :expiration_date => new_expiration_date)
    result.should be_success
    Braintree::CreditCard.find(token).expiration_date.should == new_expiration_date
  end

  it "raises an error for a nonexistent credit card" do
    lambda { Braintree::CreditCard.update("foo", {:number => TEST_CC_NUMBER}) }.should raise_error(Braintree::NotFoundError)
  end
end
