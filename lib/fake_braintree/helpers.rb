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

    def verify_credit_card?(customer_hash)
      return true if FakeBraintree.verify_all_cards

      customer_hash["credit_card"].key?("options") &&
        customer_hash["credit_card"]["options"].is_a?(Hash) &&
        customer_hash["credit_card"]["options"]["verify_card"] == true
    end

    def has_invalid_credit_card?(customer_hash)
      ! FakeBraintree::VALID_CREDIT_CARDS.include?(customer_hash["credit_card"]["number"])
    end
  end
end
