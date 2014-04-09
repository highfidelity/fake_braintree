require 'capybara'
require 'capybara/server'

class FakeBraintree::Server
  HANDLER = if defined?(Thin)
              require 'rack/handler/thin'
              Rack::Handler::Thin
            elsif defined?(Puma)
              require 'rack/handler/puma'
              Rack::Handler::Puma
            else
              raise "No Rack handler was defined! Please include \"gem 'thin'\" or \"gem 'puma'\" in your Gemfile."
            end

  def boot
    with_thin_runner do
      server = Capybara::Server.new(FakeBraintree::SinatraApp)
      server.boot
      ENV['GATEWAY_PORT'] = server.port.to_s
    end
  end

  private

  def with_thin_runner
    default_server_process = Capybara.server
    Capybara.server do |app, port|
      HANDLER.run(app, Port: port)
    end
    yield
  ensure
    Capybara.server(&default_server_process)
  end
end
