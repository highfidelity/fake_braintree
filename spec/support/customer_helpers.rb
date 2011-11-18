module CustomerHelpers
  def create_customer(credit_card_options = {})
    credit_card_options[:number] ||= TEST_CC_NUMBER
    credit_card_options[:expiration_date] ||= '04/2016'
    Braintree::Customer.create(:credit_card => credit_card_options)
  end

  def create_customer_with_invalid_card(credit_card_options = {})
    credit_card_options[:number] = '123456'
    create_customer(credit_card_options)
  end
end
