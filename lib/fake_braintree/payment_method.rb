require 'active_support/core_ext/hash/keys'

module FakeBraintree
  class PaymentMethod
    def self.tokenize_card(attributes)
      token = (Time.now.to_f * 1000).round.to_s
      FakeBraintree.registry.payment_methods[token] = attributes.stringify_keys
      token
    end
  end
end
