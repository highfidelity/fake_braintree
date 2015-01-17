require 'spec_helper'

describe 'Braintree::PaymentMethod.find' do
  it 'gets the correct credit card' do
    month = '04'
    year = '2016'
    credit_card = Braintree::PaymentMethod.find(token_for(month, year))

    expect(credit_card.bin).to eq TEST_CC_NUMBER[0, 6]
    expect(credit_card.card_type).to eq "FakeBraintree"
    expect(credit_card.last_4).to eq TEST_CC_NUMBER[-4,4]
    expect(credit_card.expiration_month).to eq month
    expect(credit_card.expiration_year).to eq  year
    expect(credit_card.unique_number_identifier).to eq TEST_CC_NUMBER
  end

  def token_for(month, year)
    braintree_credit_card_token(TEST_CC_NUMBER, [month, year].join('/'))
  end
end
