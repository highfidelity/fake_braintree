require 'spec_helper'

describe FakeBraintree, ".credit_card_from_token" do
  let(:cc_number_2)       { %w(4111 1111 1111 2222).join }
  let(:expiration_date)   { "04/2016" }
  let(:expiration_date_2) { "05/2019" }
  let(:token)             { braintree_credit_card_token(TEST_CC_NUMBER, expiration_date) }
  let(:token_2)           { braintree_credit_card_token(cc_number_2, expiration_date_2) }

  it "looks up the credit card based on a CC token" do
    credit_card = FakeBraintree.credit_card_from_token(token)
    credit_card["last_4"].should == TEST_CC_NUMBER[-4,4]
    credit_card["expiration_year"].should == "2016"
    credit_card["expiration_month"].should == "04"

    credit_card = FakeBraintree.credit_card_from_token(token_2)
    credit_card["last_4"].should == "2222"
    credit_card["expiration_year"].should == "2019"
    credit_card["expiration_month"].should == "05"
  end
end

describe FakeBraintree, ".decline_all_cards!" do
  let(:expiration_date) { "04/2016" }
  let(:token)           { braintree_credit_card_token(TEST_CC_NUMBER, expiration_date) }
  let(:amount)          { 10.00 }

  before do
    FakeBraintree.decline_all_cards!
  end

  it "declines all cards" do
    result = Braintree::CreditCard.sale(token, amount: amount)
    result.should_not be_success
  end

  it "stops declining cards after clear! is called" do
    FakeBraintree.clear!
    result = Braintree::CreditCard.sale(token, amount: amount)
    result.should be_success
  end
end

describe FakeBraintree, ".log_file_path" do
  it "is tmp/log" do
    FakeBraintree.log_file_path.should == 'tmp/log'
  end
end

describe "configuration variables" do
  subject { Braintree::Configuration }

  it "sets the environment to development" do
    subject.environment.should == :development
  end

  it "sets some fake API credentials" do
    subject.merchant_id.should == "xxx"
    subject.public_key.should == "xxx"
    subject.private_key.should == "xxx"
  end

  it "creates a log file" do
    File.exist?(FakeBraintree.log_file_path).should == true
  end

  it "logs to the correct path" do
    subject.logger.info('Logger test')
    File.readlines(FakeBraintree.log_file_path).last.should == "Logger test\n"
  end
end

describe FakeBraintree, ".clear_log!" do
  it "clears the log file" do
    %w(one two).each { |string| Braintree::Configuration.logger.info(string) }
    subject.clear_log!
    File.read(FakeBraintree.log_file_path).should == ""
  end

  it "is called by clear!" do
    FakeBraintree.expects(:clear_log!)
    FakeBraintree.clear!
  end
end

describe FakeBraintree, "VALID_CREDIT_CARDS" do
  let(:valid_credit_cards) do
    %w(4111111111111111 4005519200000004
       4009348888881881 4012000033330026
       4012000077777777 4012888888881881
       4217651111111119 4500600000000061
       5555555555554444 378282246310005
       371449635398431 6011111111111117
       3530111333300000
      )
  end

  it "includes only credit cards that are valid in production" do
    FakeBraintree::VALID_CREDIT_CARDS.sort.should == valid_credit_cards.sort
  end
end
