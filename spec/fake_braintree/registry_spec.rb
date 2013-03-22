require 'spec_helper'

describe FakeBraintree::Registry do
  it { should have_hash_accessor_for(:customers) }
  it { should have_hash_accessor_for(:subscriptions) }
  it { should have_hash_accessor_for(:failures) }
  it { should have_hash_accessor_for(:transactions) }
  it { should have_hash_accessor_for(:redirects) }
  it { should have_hash_accessor_for(:credit_cards) }
end

describe FakeBraintree::Registry, '#clear!' do
  it { should clear_hash_when_cleared(:customers) }
  it { should clear_hash_when_cleared(:subscriptions) }
  it { should clear_hash_when_cleared(:failures) }
  it { should clear_hash_when_cleared(:transactions) }
  it { should clear_hash_when_cleared(:redirects) }
  it { should clear_hash_when_cleared(:credit_cards) }
end

describe FakeBraintree::Registry, '#failure?' do
  it 'returns false if the given CC number is not marked as a failure' do
    registry.failure?('not-a-failure').should be_false
  end

  it 'returns true if the given CC number is marked as a failure' do
    registry.failures['abc123'] = 'whatever'
    registry.failure?('abc123').should be_true
  end

  let(:registry) { subject }
end
