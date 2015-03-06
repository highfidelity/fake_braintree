require 'sinatra/base'
require 'sinatra'

# TODO: why doesn't erb template work?
# replace jquery with vanilla js?
# why is all this taking you so much time?
# investigate the need for javascript_escape, make sure you know what it does
# => otherwise the string would span multiple lines, making it invalid

class CheckoutApp < Sinatra::Base

  get '/custom_checkout' do
    erb :custom_checkout
  end
end
