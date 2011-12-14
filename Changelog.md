# 0.0.6
* Flesh out the README
* Add support for transparent redirect
* Add basic support for adding add-ons
* Add basic support for adding discounts
* Lots of internal refactorings

# 0.0.5
* Add support for Braintree::Customer.find

# 0.0.4
* Allow for very basic card verification

# 0.0.3
* Ensure FakeBraintree.log_file_path directory exists
* The FakeBraintree.log_file_path attribute can now be read (it could only be set before)
* Clear log when FakeBraintree.clear! is called
* Correctly handle nonexistent subscriptions when using
  Braintree::Subscription.find
