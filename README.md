# fake\_braintree, a Braintree fake

Currently in alpha. Needs complete test coverage, then more functionality can
be added.

## Quick start
Call `FakeBraintree.activate!` to make it go. `FakeBraintree.clear!` will clear
all data, which you probably want to do before each test.

Example, in spec\_helper.rb:

    FakeBraintree.activate!

    RSpec.configure do |c|
      c.before do
        FakeBraintree.clear!
      end
    end

## Verifying credit cards

To verify every credit card you try to use, call
`FakeBraintree.verify_all_cards!`. This will stay "on" until you set
`FakeBraintree.verify_all_cards = false`.  Calling FakeBraintree.clear! _will
not_ change it. It does very basic verification: it only matches the credit card
number against these:
http://www.braintreepayments.com/docs/ruby/reference/sandbox and rejects them if
they aren't one of the listed numbers.
