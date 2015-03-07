require 'sinatra/base'
require 'fake_braintree/credit_card_serializer'

class CheckoutApp < Sinatra::Base
  get '/advanced_checkout' do
    populate_credit_cards
    @token = Braintree::ClientToken.generate
    erb :'advanced_checkout.html'
  end

  get '/custom_checkout' do
    populate_credit_cards
    @token = Braintree::ClientToken.generate
    erb :'custom_checkout.html'
  end

  get '/dropin_checkout' do
    populate_credit_cards
    @token = Braintree::ClientToken.generate(customer_id: @customer.id)
    erb :'dropin_checkout.html'
  end

  get '/credit_cards' do
    populate_credit_cards
    erb :'credit_cards.html'
  end

  post '/credit_cards' do
    Braintree::PaymentMethod.create(
      customer_id: 'customer_id',
      payment_method_nonce: params['payment_method_nonce']
    )
    redirect to('/credit_cards')
  end

  def populate_credit_cards
    begin
      @customer = Braintree::Customer.find('customer_id')
    rescue Braintree::NotFoundError
      @customer = Braintree::Customer.create(id: 'customer_id').customer
    end
    @credit_cards = @customer.credit_cards.collect do |card|
      FakeBraintree::CreditCardSerializer.new(card).to_h
    end
  end
end
