require 'forwardable'

class FakeBraintree::Server
  extend Forwardable
  def_delegators :@server, :port, :boot

  def initialize(options = {})
    app = FakeBraintree::SinatraApp
    host = '127.0.0.1'
    @server = Capybara::Server.new(app, options.fetch(:port, nil), host)
  end
end
