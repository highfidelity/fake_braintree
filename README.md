# fake\_braintree, a Braintree fake

This library is a way to test Braintree code without hitting Braintree's servers.
It uses [sham_rack](https://github.com/mdub/sham_rack) to intercept all of the
calls from Braintree's Ruby library and returns XML that the Braintree library
can parse. The whole point is not to hit the Braintree API.

Currently in alpha (i.e. it does not support every Braintree call).

## Supported API methods

* `Braintree::Customer.create`
* `Braintree::Customer.find`
* `Braintree::Subscription.create`
* `Braintree::Subscription.find`
* `Braintree::CreditCard.find`
* `Braintree::CreditCard.sale`
* `Braintree::Transaction.sale`

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

To verify every credit card you try to use, call:

    FakeBraintree.verify_all_cards!

This will stay "on" until you set

    FakeBraintree.verify_all_cards = false

Calling FakeBraintree.clear! _will not_ change this setting. It does very basic
verification: it only matches the credit card number against these:
http://www.braintreepayments.com/docs/ruby/reference/sandbox and rejects them if
they aren't one of the listed numbers.
