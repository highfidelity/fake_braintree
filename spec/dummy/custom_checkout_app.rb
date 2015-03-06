require 'sinatra/base'

class CheckoutApp < Sinatra::Base
  get '/custom_checkout' do
    @token = Braintree::ClientToken.generate
    erb :'custom_checkout.html'
  end
end
