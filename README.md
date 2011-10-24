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
