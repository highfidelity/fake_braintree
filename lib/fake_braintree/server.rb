require 'forwardable'
require 'capybara'
require 'fake_braintree/sinatra_app'

class FakeBraintree::Server
  SERVER_HOST = '127.0.0.1'

  extend Forwardable
  def_delegators :@server, :port, :boot

  def initialize(options = {})
    app = FakeBraintree::SinatraApp

    port = ENV.fetch('GATEWAY_PORT', Capybara.server_port)
    ENV['GATEWAY_PORT'] = port.to_s
    @server = Capybara::Server.new(app, port, SERVER_HOST)
  end
end
