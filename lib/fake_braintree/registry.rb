class FakeBraintree::Registry
  def initialize
    clear!
  end

  attr_accessor :customers,:subscriptions, :failures, :transactions, :redirects,
    :credit_cards, :addresses, :payment_methods

  def clear!
    @addresses       = {}
    @customers       = {}
    @subscriptions   = {}
    @failures        = {}
    @transactions    = {}
    @redirects       = {}
    @credit_cards    = {}
    @payment_methods = {}
  end

  def failure?(card_number)
    @failures.keys.include?(card_number)
  end
end
