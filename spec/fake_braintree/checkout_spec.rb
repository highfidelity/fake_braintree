require 'spec_helper'
require 'capybara/rspec'

feature 'checkout', js: true do
  scenario 'advanced integration' do
    visit('/advanced_checkout')

    fill_in('number', with: TEST_CC_NUMBER)
    fill_in('expiration-date', with: '10/20')
    find('#submit').click

    find('#status', text: 'success')
    visit('/advanced_checkout')

    expect(page).to have_content('ending in 11')
  end

  scenario 'custom integration' do
    visit('/custom_checkout')

    fill_in('number', with: TEST_CC_NUMBER)
    fill_in('expiration-date', with: '10/20')
    find('#submit').click

    expect(page).to have_content('ending in 11')
  end
end
