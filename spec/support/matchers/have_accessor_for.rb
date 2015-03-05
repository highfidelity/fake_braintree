RSpec::Matchers.define :have_hash_accessor_for do |property|
  match do |object|
    object.send(property.to_sym)['key'] = 'value'
    expect(object.send(property.to_sym)['key']).to eq 'value'
  end

  failure_message do
    "Expected #{object} to have accessor for #{property}, but it did not."
  end
end
