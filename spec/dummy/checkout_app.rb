require 'sinatra/base'
require 'fake_braintree/credit_card_serializer'

class CheckoutApp < Sinatra::Base
  get '/advanced_checkout' do
    @token = Braintree::ClientToken.generate
    erb :'advanced_checkout.html'
  end

  get '/custom_checkout' do
    @token = Braintree::ClientToken.generate
    erb :'custom_checkout.html'
  end

  get '/dropin_checkout' do
    @token = Braintree::ClientToken.generate(customer_id: customer.id)
    erb :'dropin_checkout.html'
  end

  get '/credit_cards' do
    @credit_cards = customer.credit_cards.collect do |card|
      FakeBraintree::CreditCardSerializer.new(card).to_h
    end
    erb :'credit_cards.html'
  end

  post '/credit_cards' do
    customer
    Braintree::PaymentMethod.create(
      customer_id: 'customer_id',
      payment_method_nonce: params['payment_method_nonce']
    )
    redirect to('/credit_cards')
  end

  def customer
    begin
      @customer = Braintree::Customer.find('customer_id')
    rescue Braintree::NotFoundError
      @customer = Braintree::Customer.create(id: 'customer_id').customer
    end
    @customer
  end
end
