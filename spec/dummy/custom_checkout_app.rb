require 'sinatra/base'

class CheckoutApp < Sinatra::Base
  get '/custom_checkout' do
    @token = Braintree::ClientToken.generate
    erb :'custom_checkout.html'
  end

  post '/credit_cards' do
    Braintree::PaymentMethod.create(
      payment_method_nonce: params['payment_method_nonce']
    )
    204
  end
end
