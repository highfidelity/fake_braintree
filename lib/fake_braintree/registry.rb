class FakeBraintree::Registry
  def initialize
    clear!
  end

  attr_accessor :customers, :subscriptions, :failures, :transactions, :redirects

  def clear!
    @customers     = {}
    @subscriptions = {}
    @failures      = {}
    @transactions  = {}
    @redirects     = {}
  end

  def failure?(card_number)
    @failures.keys.include?(card_number)
  end

  def credit_card_from_token(token)
    @customers.values.detect do |customer|
      next unless customer.key?("credit_cards")

      card = customer["credit_cards"].detect {|card| card["token"] == token }
      return card if card
    end
  end
end
