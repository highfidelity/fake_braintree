require 'bundler/setup'
require 'fake_braintree'

trap('INT') do
  puts "Graceful shutdown...goodbye."
  exit 0
end

loop { sleep 1 }
