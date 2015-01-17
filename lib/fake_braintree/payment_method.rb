module FakeBraintree
  class PaymentMethod
    def self.tokenize_card(attributes)
      token = (Time.now.to_f * 1000).round
      FakeBraintree.registry.payment_methods[token] = attributes
      token
    end
  end
end
