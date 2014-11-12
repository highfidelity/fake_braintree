module MerchantAccountHelpers
  def create_merchant_account
    Braintree::MerchantAccount.create(
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
  end
end
