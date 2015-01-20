# fake\_braintree, a Braintree fake [![Build Status](https://secure.travis-ci.org/thoughtbot/fake_braintree.svg)](http://travis-ci.org/thoughtbot/fake_braintree)


This library is a way to test [Braintree](http://www.braintreepayments.com/)
code without hitting Braintree's servers. It uses
[Capybara::Server](https://github.com/jnicklas/capybara/blob/master/lib/capybara/server.rb)
to intercept all of the calls from Braintree's Ruby library and returns XML that
the Braintree library can parse. The whole point is not to hit the Braintree
API.

It supports a lot of Braintree methods, but it does not support every single one
of them (yet).

## Supported API methods

### Address
* `Braintree::Address.create`

### CreditCard
* `Braintree::CreditCard.create`
* `Braintree::CreditCard.delete`
* `Braintree::CreditCard.find`
* `Braintree::CreditCard.sale`
* `Braintree::CreditCard.update`

### Customer
* `Braintree::Customer.create` (including adding add-ons and discounts)
* `Braintree::Customer.delete`
* `Braintree::Customer.find`
* `Braintree::Customer.update`

### PaymentMethod
* `Braintree::PaymentMethod.create`
* `Braintree::PaymentMethod.find`
* `Braintree::PaymentMethod.update`

### Subscription
* `Braintree::Subscription.cancel`
* `Braintree::Subscription.create`
* `Braintree::Subscription.find`
* `Braintree::Subscription.update`
* `Braintree::Subscription.retry_charge`

### Transaction
* `Braintree::Transaction.find`
* `Braintree::Transaction.refund`
* `Braintree::Transaction.sale`
* `Braintree::Transaction.void`
* `Braintree::Transaction.submit_for_settlement`

### TransparentRedirect
* `Braintree::TransparentRedirect.confirm` (only for creating customers)
* `Braintree::TransparentRedirect.url`

## Quick start
Require the library and activate it to start the API server:

    require 'fake_braintree'
    FakeBraintree.activate!

To run the server on a specific port, pass in the `:gateway_port` option:

    FakeBraintree.activate!(gateway_port: 1234)

`FakeBraintree.clear!` will clear all data, which you almost certainly want to
do before each test.

Full example:

    # spec/spec_helper.rb
    require 'fake_braintree'
    FakeBraintree.activate!

    RSpec.configure do |c|
      c.before do
        FakeBraintree.clear!
      end
    end

If you're using Cucumber, add this too:

    # features/support/env.rb
    require 'fake_braintree'
    FakeBraintree.activate!

    Before do
      FakeBraintree.clear!
    end

It is advised to run your tests with `js: true` (RSpec) or `@javascript`
(Cucumber), so that the requests correctly go through `FakeBraintree`. You might
want to take a look at
[capybara-webkit](https://github.com/thoughtbot/capybara-webkit).

## Don't set the Braintree environment

`fake_braintree` sets `Braintree::Configuration.environment = :development`. If
your code sets it to anything else (like `:sandbox`), then `fake_braintree` won't
work.

# Credit Cards

* `credit_card.card_type` will always be `"FakeBraintree"`.

## Verifying credit cards

To verify every credit card you try to use, call:

    FakeBraintree.verify_all_cards!

This will stay "on" until you set

    FakeBraintree.verify_all_cards = false

Calling `FakeBraintree.clear!` _will not_ change this setting. It does very basic
verification: it only matches the credit card number against these:
http://www.braintreepayments.com/docs/ruby/reference/sandbox and rejects them if
they aren't one of the listed numbers.

## Declining credit cards

To decline every card you try, call:

    FakeBraintree.decline_all_cards!

This will decline all cards until you call

    FakeBraintree.clear!

This behavior is different from `FakeBraintree.verify_all_cards`, which will
stay on even when `clear!` is called.

Note that after `decline_all_cards!` is set, Braintree will still create
customers, but will not be able to charge them (so charging for e.g. a subscription
will fail). Setting `verify_all_cards!`, on the other hand, will prevent
creation of customers with bad credit cards - Braintree won't even get to trying
to charge them.

## Generating transactions

You can generate a transaction using `FakeBraintree.generate_transaction`. This
is for use in testing, e.g.
`before { user.transaction = FakeBraintree.generate_transaction }`.

It takes the following options:

* `:subscription_id`: the ID of the subscription associated with the transaction.
* `:created_at`: when the transaction was created (defaults to `Time.now`)
* `:amount`: the amount of the transaction
* `:status`: the status of the transaction, e.g. `Braintree::Transaction::Status::Failed`

Any or all of these can be nil, and in fact are nil by default. You can also
call it with no arguments.

Full example:

    transaction = FakeBraintree.generate_transaction(
      amount: '20.00',
      status: Braintree::Transaction::Status::Settled,
      subscription_id: 'foobar',
      created_at: Time.now + 60
    )

    p transaction
    # {
    #   "status_history" =>
    #     [{
    #       "timestamp"  => 2011-11-20 12:57:25 -0500,
    #       "amount"     => "20.00",
    #       "status"     => "settled",
    #       "created_at" => 2011-11-20 12:58:25 -0500
    #     }],
    #   "subscription_id" => "foobar"
    # }

Note that the generated transaction is not saved in `fake_braintree` - the
method just gives you a hash.

## Adding your own transactions

If you want `fake_braintree` to be aware of a transaction, you can add it to the
`FakeBraintree.registry.transactions` hash like this:


```ruby
transaction_id = "something"
example_response = { "id" => transaction_id, "amount" => "10.0", "type" => "credit", "status" => "authorized" }
FakeBraintree.registry.transactions[transaction_id] = example_response
```

Now you can do `Braintree::Transaction.find("something")` and it will find that
transaction.

Not all of the keys in `example_response` are necessary, but you'll probably
want at least `id` and `amount`, depending on the type of response.

`FakeBraintree.registry.transactions` will be cleared when you call
`FakeBraintree.clear!`.


## Running the tests

During tests, debug-level logs will be sent to `tmp/braintree_log`. This is
useful for seeing which URLs Braintree is actually hitting.

Credits
-------

![thoughtbot](http://thoughtbot.com/images/tm/logo.png)

Fake Braintree is maintained and funded by [thoughtbot, inc](http://thoughtbot.com/community)

Thank you to all [the contributors](https://github.com/thoughtbot/fake_braintree/contributors)!

The names and logos for thoughtbot are trademarks of thoughtbot, inc.

License
-------

Fake Braintree is Copyright © 2011-2013 thoughtbot. It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
