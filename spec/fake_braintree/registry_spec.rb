require 'spec_helper'

describe FakeBraintree::Registry do
  it "exposes a customers accessor" do
    registry.customers['abc123'] = "Bob"
    registry.customers['abc123'].should == "Bob"
  end

  it "exposes a subscriptions accessor" do
    registry.subscriptions['abc123'] = "Bob"
    registry.subscriptions['abc123'].should == "Bob"
  end

  it "exposes a failures accessor" do
    registry.failures['abc123'] = "Bob"
    registry.failures['abc123'].should == "Bob"
  end

  it "exposes a transactions accessor" do
    registry.transactions['abc123'] = "Bob"
    registry.transactions['abc123'].should == "Bob"
  end

  it "exposes a redirects accessor" do
    registry.redirects['abc123'] = "Bob"
    registry.redirects['abc123'].should == "Bob"
  end

  it "exposes a credit_cards accessor" do
    registry.credit_cards['abc123'] = "Bob"
    registry.credit_cards['abc123'].should == "Bob"
  end

  let(:registry) { subject }
end

describe FakeBraintree::Registry, "#clear!" do
  it "clears stored customers" do
    registry.customers['abc123'] = "Bob"
    registry.clear!
    registry.customers.should be_empty
  end

  it "clears stored subscriptions" do
    registry.subscriptions['abc123'] = "Bob"
    registry.clear!
    registry.subscriptions.should be_empty
  end

  it "clears stored failures" do
    registry.failures['abc123'] = "Bob"
    registry.clear!
    registry.failures.should be_empty
  end

  it "clears stored transactions" do
    registry.transactions['abc123'] = "Bob"
    registry.clear!
    registry.transactions.should be_empty
  end

  it "clears stored redirects" do
    registry.redirects['abc123'] = "Bob"
    registry.clear!
    registry.redirects.should be_empty
  end

  let(:registry) { subject }
end

describe FakeBraintree::Registry, "#failure?" do
  it "returns false if the given CC number is not marked as a failure" do
    registry.failure?('not-a-failure').should be_false
  end

  it "returns true if the given CC number is marked as a failure" do
    registry.failures['abc123'] = 'whatever'
    registry.failure?('abc123').should be_true
  end

  let(:registry) { subject }
end
