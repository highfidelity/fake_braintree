require 'forwardable'

class FakeBraintree::Server
  SERVER_HOST = '127.0.0.1'

  extend Forwardable
  def_delegators :@server, :port, :boot

  def initialize(options = {})
    app = FakeBraintree::SinatraApp
    @server = Capybara::Server.new(app, options.fetch(:port, nil), SERVER_HOST)
  end
end
