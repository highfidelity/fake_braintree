require 'capybara'
require 'capybara-webkit'
require 'fake_braintree/asset_versions'
require 'net/http'

module FakeBraintree
  class ClientAssets
    URL = 'https://js.braintreegateway.com/v2/braintree.js'

    def initialize
      @asset_versions = FakeBraintree::AssetVersions.new
    end

    def save
      if client_version == @asset_versions.client_version
        puts 'Client assets up to date'
        return
      end

      File.write('spec/dummy/public/braintree.js', js)
      @asset_versions.client_version = client_version
      puts "Client assets updated to version #{client_version}"
    end

    def dropin_version
      @dropin_version ||= session.evaluate_script('braintree.dropin.VERSION')
    end

    private

    def client_version
      @client_version ||= session.evaluate_script('braintree.VERSION')
    end

    def js
      return @js unless @js.nil?
      puts 'Downloading braintree.js'
      @js = Net::HTTP.get(URI(URL))
    end

    def session
      return @session unless @session.nil?
      @session = Capybara::Session.new(:webkit, ->{})
      @session.execute_script(js)
      @session
    end
  end
end
