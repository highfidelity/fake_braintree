# fake\_braintree, a Braintree fake

This library is a way to test Braintree code without hitting Braintree's servers.
It uses [Capybara::Server](https://github.com/jnicklas/capybara/blob/master/lib/capybara/server.rb)
to intercept all of the calls from Braintree's Ruby library and returns XML that the Braintree library
can parse. The whole point is not to hit the Braintree API.

Currently in alpha (i.e. it does not support every Braintree call).

## Supported API methods

### Customer
* `Braintree::Customer.find`
* `Braintree::Customer.create`
* `Braintree::Customer.update`

### Subscription
* `Braintree::Subscription.find`
* `Braintree::Subscription.create`

### CreditCard
* `Braintree::CreditCard.find`
* `Braintree::CreditCard.sale`

### Transaction
* `Braintree::Transaction.sale`

### TransparentRedirect
* `Braintree::TransparentRedirect.url`
* `Braintree::TransparentRedirect.confirm` (only for creating customers)

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

## Declining credit cards

To decline every card you try, call:

    FakeBraintree.decline_all_cards!

This will decline all cards until you call

    FakeBraintree.clear!

This behavior is different from FakeBraintree.verify\_all\_cards, which will
stay on even when `clear!` is called.
