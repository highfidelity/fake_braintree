require 'spec_helper'
require 'capybara/rspec'

feature 'custom checkout', js: true do
  scenario 'tokenize card' do
    visit('/custom_checkout')

    fill_in('number', with: TEST_CC_NUMBER)
    fill_in('expiration-date', with: '10/20')
    find('#submit').click
    find('#status', text: 'success')

    # ugly code follows, will be replaced in soon
    nonce = page.evaluate_script("$('#nonce').html()")
    payment_method = FakeBraintree.registry.payment_methods[nonce]
    expect(payment_method['number']).to eq TEST_CC_NUMBER

    # the ugly code gains a friend!
    credit_card = FakeBraintree.registry.credit_cards.values.first
    expect(credit_card['number']).to eq TEST_CC_NUMBER
  end
end
