require 'capybara'
require 'capybara/server'
require 'rack/handler/webrick'

class FakeBraintree::Server
  def boot
    with_webrick_runner do
      server = Capybara::Server.new(FakeBraintree::SinatraApp)
      server.boot
      ENV['GATEWAY_PORT'] = server.port.to_s
    end
  end

  private

  def with_webrick_runner
    default_server_process = Capybara.server
    Capybara.server do |app, port|
      # Quiet logging, matches Mongrel
      access_log = [['/dev/null', '']]

      Rack::Handler::WEBrick.run(app, :AccessLog => access_log, :Port => port)
    end
    yield
  ensure
    Capybara.server(&default_server_process)
  end
end
