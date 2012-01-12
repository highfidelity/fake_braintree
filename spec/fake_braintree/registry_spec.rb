require 'spec_helper'

describe FakeBraintree::Registry do
  it { should have_hash_accessor_for(:customers) }
  it { should have_hash_accessor_for(:subscriptions) }
  it { should have_hash_accessor_for(:failures) }
  it { should have_hash_accessor_for(:transactions) }
  it { should have_hash_accessor_for(:redirects) }
  it { should have_hash_accessor_for(:credit_cards) }
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
