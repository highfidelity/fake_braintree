RSpec::Matchers.define :have_hash_accessor_for do |property|
  match do |object|
    object.send(property.to_sym)['key'] = 'value'
    object.send(property.to_sym)['key'].should == 'value'
  end

  failure_message_for_should do
    "Expected #{object} to have accessor for #{property}, but it did not."
  end
end
