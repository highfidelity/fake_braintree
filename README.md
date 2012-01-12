# fake\_braintree, a Braintree fake [![Build Status](https://secure.travis-ci.org/thoughtbot/fake_braintree.png)](http://travis-ci.org/thoughtbot/fake_braintree)


This library is a way to test Braintree code without hitting Braintree's servers.
It uses [Capybara::Server](https://github.com/jnicklas/capybara/blob/master/lib/capybara/server.rb)
to intercept all of the calls from Braintree's Ruby library and returns XML that the Braintree library
can parse. The whole point is not to hit the Braintree API.

Currently in alpha (i.e. it does not support every Braintree call).

## Supported API methods

### Customer
* `Braintree::Customer.find`
* `Braintree::Customer.create` (including adding add-ons and discounts)
* `Braintree::Customer.update`
* `Braintree::Customer.delete`

### Subscription
* `Braintree::Subscription.find`
* `Braintree::Subscription.create`
* `Braintree::Subscription.update`
* `Braintree::Subscription.cancel`

### CreditCard
* `Braintree::CreditCard.find`
* `Braintree::CreditCard.sale`
* `Braintree::CreditCard.update`

### Transaction
* `Braintree::Transaction.sale`

### TransparentRedirect
* `Braintree::TransparentRedirect.url`
* `Braintree::TransparentRedirect.confirm` (only for creating customers)

## Quick start
Just require the library and you're good to go:

    require 'fake_braintree'

`FakeBraintree.clear!` will clear all data, which you almost certainly want to
do before each test.

Full example:

    # spec/spec_helper.rb
    require 'fake_braintree'

    RSpec.configure do |c|
      c.before do
        FakeBraintree.clear!
      end
    end

If you're using Cucumber, add this too:

    # features/support/env.rb
    require 'fake_braintree'

    Before do
      FakeBraintree.clear!
    end

## Spork

To use fake\_braintree with Spork, do this:

    # Gemfile
    group :test do
      gem 'fake_braintree', :require => false
    end

    # spec/spec_helper.rb
    Spork.each_run do
      require 'fake_braintree'
      # ...other FakeBraintree configuration, for example:
      # FakeBraintree.verify_all_cards!
    end

    # features/support/env.rb
    Spork.each_run do
      require 'fake_braintree'
      # ...other FakeBraintree configuration, for example:
      # FakeBraintree.verify_all_cards!
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

    transaction = FakeBraintree.generate_transaction(:amount => '20.00',
                                                     :status => Braintree::Transaction::Status::Settled,
                                                     :subscription_id => 'foobar',
                                                     :created_at => Time.now + 60)
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
