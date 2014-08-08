require 'spec_helper'

describe FakeBraintree, '.decline_all_cards!' do
  before { FakeBraintree.decline_all_cards! }

  it 'declines all cards' do
    expect(create_sale).not_to be_success
  end

  it 'stops declining cards after clear! is called' do
    FakeBraintree.clear!
    expect(create_sale).to be_success
  end

  def create_sale
    Braintree::CreditCard.sale(cc_token, amount: 10.00)
  end
end

describe FakeBraintree, '.log_file_path' do
  it 'is tmp/log' do
    expect(FakeBraintree.log_file_path).to eq 'tmp/log'
  end
end

describe Braintree::Configuration do
  subject { Braintree::Configuration }

  it 'is running in the development environment' do
    expect(subject.environment).to eq :development
  end

  it 'has some fake API credentials' do
    expect(subject.merchant_id).to eq 'xxx'
    expect(subject.public_key).to eq 'xxx'
    expect(subject.private_key).to eq 'xxx'
  end
end

describe FakeBraintree do
  it 'creates a log file' do
    expect(File.exist?(FakeBraintree.log_file_path)).to eq true
  end
end

describe FakeBraintree, '.clear_log!' do
  it 'clears the log file' do
    write_to_log
    subject.clear_log!
    expect(File.read(FakeBraintree.log_file_path)).to eq ''
  end

  it 'is called by clear!' do
    FakeBraintree.stub(:clear_log!)

    FakeBraintree.clear!

    expect(FakeBraintree).to have_received(:clear_log!)
  end

  def write_to_log
    Braintree::Configuration.logger.info('foo bar baz')
  end
end

describe FakeBraintree, 'VALID_CREDIT_CARDS' do
  it 'includes only credit cards that are valid in the Braintree sandbox' do
    valid_credit_cards = %w(
      4111111111111111 4005519200000004
      4009348888881881 4012000033330026
      4012000077777777 4012888888881881
      4217651111111119 4500600000000061
      5555555555554444 378282246310005
      371449635398431 6011111111111117
      3530111333300000
    )

    expect(FakeBraintree::VALID_CREDIT_CARDS.sort).to eq valid_credit_cards.sort
  end
end

describe FakeBraintree, '.failure_response' do
  it 'can be called with no arguments' do
    expect { FakeBraintree.failure_response }.not_to raise_error
  end
end

describe FakeBraintree, '.generate_transaction' do
  it 'allows setting the subscription id' do
    transaction = FakeBraintree.generate_transaction(subscription_id: 'foobar')
    expect(transaction['subscription_id']).to eq 'foobar'
  end

  it 'allows setting created_at' do
    time = Time.now
    transaction = FakeBraintree.generate_transaction(created_at: time)
    expect(transaction['created_at']).to eq time
  end

  it 'sets created_at to Time.now by default' do
    Timecop.freeze do
      transaction = FakeBraintree.generate_transaction
      expect(transaction['created_at']).to eq Time.now
    end
  end

  it 'has the correct amount' do
    transaction = FakeBraintree.generate_transaction(amount: '20.00')
    expect(transaction['amount']).to eq '20.00'
  end

  it 'allows no arguments' do
    expect { FakeBraintree.generate_transaction }.not_to raise_error
  end

  context 'status_history' do
    it 'returns a hash with a status_history key' do
      expect(FakeBraintree.generate_transaction(amount: '20')).to have_key('status_history')
    end

    it 'has a timestamp of Time.now' do
      Timecop.freeze do
        transaction = FakeBraintree.generate_transaction(
          status: Braintree::Transaction::Status::Failed,
          subscription_id: 'my_subscription_id'
        )
        expect(transaction['status_history'].first['timestamp']).to eq Time.now
      end
    end

    it 'has the desired amount' do
      transaction = FakeBraintree.generate_transaction(amount: '20.00')
      expect(transaction['status_history'].first['amount']).to eq '20.00'
    end

    it 'has the desired status' do
      status = Braintree::Transaction::Status::Failed
      transaction = FakeBraintree.generate_transaction(status: status)
      expect(transaction['status_history'].first['status']).to eq status
    end
  end
end
