RSpec::Matchers.define :clear_hash_when_cleared do |property|
  match do |object|
    object.send(property.to_sym)['key'] = 'value'
    object.clear!
    expect(object.send(property.to_sym)).to be_empty
  end

  failure_message do
    "Expected #{object} to clear #{property} hash after clear!, but it did not."
  end
end
