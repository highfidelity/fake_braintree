require 'sinatra/base'
require 'fake_braintree/credit_card_serializer'

class CheckoutApp < Sinatra::Base
  get '/custom_checkout' do
    begin
      customer = Braintree::Customer.find('customer_id')
    rescue Braintree::NotFoundError
      customer = Braintree::Customer.create(id: 'customer_id').customer
    end
    @credit_cards = customer.credit_cards.collect do |card|
      FakeBraintree::CreditCardSerializer.new(card).to_h
    end

    @token = Braintree::ClientToken.generate
    erb :'custom_checkout.html'
  end

  post '/credit_cards' do
    Braintree::PaymentMethod.create(
      customer_id: 'customer_id',
      payment_method_nonce: params['payment_method_nonce']
    )
    204
  end
end
