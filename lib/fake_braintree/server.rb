require 'forwardable'
require 'capybara'
require 'fake_braintree/sinatra_app'

class FakeBraintree::Server
  def boot
    server = Capybara::Server.new(FakeBraintree::SinatraApp)
    server.boot
    ENV['GATEWAY_PORT'] = server.port.to_s
  end
end
