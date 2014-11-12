require 'spec_helper'

describe 'Braintree::MerchantAccount.create' do
  it 'successfully creates a merchant account' do
    result = Braintree::MerchantAccount.create(
      tos_accepted: true,
      # master_merchant_account_id: MERCHANT_ID,
      individual: {
        first_name: 'first',
        last_name: 'last',
        email: 'test@test.com',
        date_of_birth: '1971-01-01',
        address: {
          street_address: '1 E Main St',
          locality: 'Chicago',
          region: 'Illinois',
          postal_code: '60622',
        }
      },
      funding: {
        destination: 'bank',
        account_number: '9900000000',
        routing_number: '021000021'
      }
    )
    expect(result).to be_success
  end

end

describe 'Braintree::MerchantAccount.find' do
  it 'successfully finds a merchant account' do
    result = Braintree::MerchantAccount.create(
      individual: {
        first_name: 'Bob',
        last_name: 'Smith'
      }
    )
    expect(Braintree::MerchantAccount.find(result.merchant_account.id).individual_details.first_name).to eq 'Bob'
  end

  it 'raises an error for a nonexistent customer' do
    expect(lambda { Braintree::MerchantAccount.find('foo') }).to raise_error(Braintree::NotFoundError)
  end

  it 'finds merchant account created with custom id' do
    Braintree::MerchantAccount.create(
        id: 'bob-smith',
        individual: {
          first_name: 'Bob',
          last_name: 'Smith'
        }
    )

    expect(Braintree::MerchantAccount.find('bob-smith').individual_details.first_name).to eq 'Bob'
  end

  it 'finds merchant account created with custom integer id' do
    Braintree::MerchantAccount.create(
        id: 1,
        individual: {
          first_name: 'Bob',
          last_name: 'Smith'
        }
    )

    expect(Braintree::MerchantAccount.find(1).individual_details.first_name).to eq 'Bob'
  end
end

describe 'Braintree::MerchantAccount.update' do
  it 'successfully updates a merchant account' do
    merchant_account_id = create_merchant_account.merchant_account.id
    result = Braintree::MerchantAccount.update(merchant_account_id, individual: { first_name: 'Jerry'} )
    
    expect(result).to be_success
    expect(Braintree::MerchantAccount.find(merchant_account_id).individual_details.first_name).to eq 'Jerry'
  end

  it 'raises an error for a nonexistent merchant account' do
    expect { Braintree::MerchantAccount.update('foo', { individual: { first_name: 'Bob' } }) }.to raise_error(Braintree::NotFoundError)
  end

end
