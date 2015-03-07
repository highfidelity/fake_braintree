require 'spec_helper'
require 'capybara/rspec'

feature 'checkout', js: true do
  scenario 'advanced integration' do
    visit('/advanced_checkout')

    fill_in('number', with: TEST_CC_NUMBER)
    fill_in('expiration-date', with: '10/20')
    find('#submit').click

    find('#status', text: 'success')
    visit('/credit_cards')

    expect(page).to have_content('ending in 11')
  end

  scenario 'custom integration' do
    visit('/custom_checkout')

    fill_in('number', with: TEST_CC_NUMBER)
    fill_in('expiration-date', with: '10/20')
    find('#submit').click

    expect(page).to have_content('ending in 11')
  end

  scenario 'dropin integration' do
    visit('/dropin_checkout')

    within_frame('braintree-dropin-frame') do
      fill_in('credit-card-number', with: TEST_CC_NUMBER)
      fill_in('expiration', with: '10/20')
      fill_in('cvv', with: '411')
    end
    find('#submit').click

    expect(page).to have_content('ending in 11')

    visit('/dropin_checkout')
    within_frame('braintree-dropin-frame') do
      expect(page).to have_content('ending in 11')
    end
  end
end
