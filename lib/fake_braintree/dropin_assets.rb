require 'fake_braintree/asset_versions'

module FakeBraintree
  class DropinAssets
    ASSETS_URL = 'https://assets.braintreegateway.com/dropin'
    ASSETS_PATH = 'lib/fake_braintree/braintree_assets/dropin'
    ASSETS = %w(
      braintree-dropin-internal.min.js
      braintree-dropin.css
      inline-frame.html
      modal-frame.html
      vendor/jquery-2.1.0.js
      vendor/modernizr.js
      vendor/normalize.css
      images/2x-sf9a66b4f5a.png
    )

    def initialize(version)
      @version = version
      @asset_versions = FakeBraintree::AssetVersions.new
    end

    def save
      if @asset_versions.dropin_version == @version
        puts 'Dropin assets up to date'
        return
      end

      FileUtils.rm_rf(ASSETS_PATH)

      origin_root = "#{ASSETS_URL}/#{@version}/"
      target_root = "#{ASSETS_PATH}/#{@version}/"
      ASSETS.each do |asset|
        puts "Downloading #{asset}"
        system(
          "curl #{origin_root + asset} -o #{target_root + asset} --create-dirs"
        )
      end

      @asset_versions.dropin_version = @version
      puts "Dropin assets updated to version #{@version}"
    end
  end
end
