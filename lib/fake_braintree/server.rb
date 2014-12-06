require 'forwardable'

class FakeBraintree::Server
  extend Forwardable
  def_delegators :@server, :port, :boot

  def initialize(options = {})
    app = FakeBraintree::SinatraApp
    @server = Capybara::Server.new(app, options.fetch(:port, nil))
  end
end
