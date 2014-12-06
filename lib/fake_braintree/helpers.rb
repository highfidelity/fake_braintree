require 'digest/md5'
require 'active_support/gzip'

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
      md5("#{merchant_id}#{Time.now.to_f}")
    end
  end
end
