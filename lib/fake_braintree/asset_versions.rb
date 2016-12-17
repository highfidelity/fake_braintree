require 'yaml'

module FakeBraintree
  class AssetVersions
    attr_reader :client_version, :dropin_version

    def initialize
      @data = YAML::load_file('asset_versions.yml')

      @client_version = @data['client_version']
      @dropin_version = @data['dropin_version']
    end

    def client_version=(val)
      @data['client_version'] = val
      save
    end

    def dropin_version=(val)
      @data['dropin_version'] = val
      save
    end

    private

    def save
      File.write('asset_versions.yml', @data.to_yaml)
    end
  end
end
