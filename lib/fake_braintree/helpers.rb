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
      chars = 'abcdefghjkmnopqrstuvwxyzABCDEFGHJKLMNOPQRSTUVWXYZ0123456789'
      res = ''
      6.times { res << chars[rand(chars.size)] }
      res
    end
  end
end
