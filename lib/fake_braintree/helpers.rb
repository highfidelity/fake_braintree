require 'digest/md5'
require 'active_support'
require 'active_support/core_ext'

module FakeBraintree
  module Helpers
    def gzip(content)
      ActiveSupport::Gzip.compress(content)
    end

    def gzipped_response(status_code, uncompressed_content)
      [status_code, { "Content-Encoding" => "gzip" }, gzip(uncompressed_content)]
    end

    def md5(content)
      Digest::MD5.hexdigest(content)
    end
  end
end
