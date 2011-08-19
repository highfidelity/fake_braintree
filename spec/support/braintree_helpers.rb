module BraintreeHelpers
  def create_braintree_customer(cc_number, expiration_date)
    Braintree::Customer.create(
      email: "me@example.com",
      credit_card: {
        number: cc_number,
        expiration_date: expiration_date
      }
    ).customer
  end

  def braintree_credit_card_token(cc_number, expiration_date)
    create_braintree_customer(cc_number, expiration_date).credit_cards[0].token
  end
end
