require 'sinatra/base'

module FakeBraintree
  class SinatraApp < Sinatra::Base
    set :show_exceptions, false
    set :dump_errors, true
    set :raise_errors, true
    disable :logging

    include Helpers

    # Braintree::Customer.create
    post "/merchants/:merchant_id/customers" do
      customer = Customer.new(request, params[:merchant_id])
      if customer.invalid?
        customer.failure_response
      else
        customer_hash = customer.customer_hash
        FakeBraintree.customers[customer_hash["id"]] = customer_hash
        gzipped_response(201, customer_hash.to_xml(:root => 'customer'))
      end
    end

    # Braintree::Customer.find
    get "/merchants/:merchant_id/customers/:id" do
      customer = FakeBraintree.customers[params[:id]]
      if customer
        gzipped_response(200, customer.to_xml(:root => 'customer'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Subscription.create
    post "/merchants/:merchant_id/subscriptions" do
      response_hash = Subscription.new(request).response_hash

      FakeBraintree.subscriptions[response_hash["id"]] = response_hash
      gzipped_response(201, response_hash.to_xml(:root => 'subscription'))
    end

    # Braintree::Subscription.find
    get "/merchants/:merchant_id/subscriptions/:id" do
      subscription = FakeBraintree.subscriptions[params[:id]]
      if subscription
        gzipped_response(200, subscription.to_xml(:root => 'subscription'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::CreditCard.find
    get "/merchants/:merchant_id/payment_methods/:credit_card_token" do
      credit_card = FakeBraintree.credit_card_from_token(params[:credit_card_token])
      gzipped_response(200, credit_card.to_xml(:root => "credit_card"))
    end

    # Braintree::Transaction.sale
    # Braintree::CreditCard.sale
    post "/merchants/:merchant_id/transactions" do
      if FakeBraintree.decline_all_cards?
        gzipped_response(422, FakeBraintree.create_failure.to_xml(:root => 'api_error_response'))
      else
        transaction          = Hash.from_xml(request.body)["transaction"]
        transaction_id       = md5("#{params[:merchant_id]}#{Time.now.to_f}")
        transaction_response = {"id" => transaction_id, "amount" => transaction["amount"]}
        FakeBraintree.transaction.replace(transaction_response)
        gzipped_response(200, transaction_response.to_xml(:root => "transaction"))
      end
    end

    # Braintree::Transaction.find
    get "/merchants/:merchant_id/transactions/:transaction_id" do
      if FakeBraintree.transaction["id"] == params[:transaction_id]
        gzipped_response(200, FakeBraintree.transaction.to_xml(:root => "transaction"))
      else
        gzipped_response(404, {})
      end
    end
  end
end
