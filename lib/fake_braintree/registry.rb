class FakeBraintree::Registry
  def initialize
    clear!
  end

  attr_accessor :customers,:subscriptions, :failures, :transactions, :redirects,
    :credit_cards

  def clear!
    @customers     = {}
    @subscriptions = {}
    @failures      = {}
    @transactions  = {}
    @redirects     = {}
    @credit_cards  = {}
  end

  def failure?(card_number)
    @failures.keys.include?(card_number)
  end
end
