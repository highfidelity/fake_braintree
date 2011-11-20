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
* `Braintree::Subscription.update`

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
* `:amount`: the amount of the transaction
* `:status`: the status of the transaction, e.g. `Braintree::Transaction::Status::Failed`

Any or all of these can be nil, and in fact are nil by default.

Full example:

    transaction = FakeBraintree.generate_transaction(:amount => '20.00',
                                                     :status => Braintree::Transaction::Status::Settled,
                                                     :subscription_id => 'foobar')
    p transaction
    # {
    #   "status_history" =>
    #     [{
    #       "timestamp" => 2011-11-20 12:57:25 -0500,
    #       "amount"    => "20.00",
    #       "status"    => "settled"
    #     }],
    #   "subscription_id" => "foobar"
    # }
