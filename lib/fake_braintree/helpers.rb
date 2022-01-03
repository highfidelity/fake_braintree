require 'digest/md5'
require 'active_support/gzip'
require 'securerandom'

module FakeBraintree
  module Helpers
    def gzip(content)
      ActiveSupport::Gzip.compress(content)
    end

    def gzipped_response(status_code, uncompressed_body)
      [status_code, { 'Content-Encoding' => 'gzip' }, gzip(uncompressed_body)]
    end

    def md5(content)
      Digest::MD5.hexdigest(content)
    end

    def create_id(merchant_id)
      SecureRandom.hex
    end
  end
end
