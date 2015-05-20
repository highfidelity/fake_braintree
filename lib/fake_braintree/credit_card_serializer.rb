module FakeBraintree
  class CreditCardSerializer
    def initialize(credit_card)
      @credit_card = credit_card
    end

    def to_h
      last_2 = @credit_card.last_4[-2..-1]
      card_type = @credit_card.card_type
      {
        type: 'CreditCard',
        description: "ending in #{last_2}",
        details: {
          cardType: card_type,
          lastTwo: last_2
        }
      }
    end
  end
end
