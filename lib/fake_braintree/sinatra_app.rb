require 'sinatra/base'
require 'active_support/core_ext/hash/conversions'
require 'fake_braintree/customer'
require 'fake_braintree/subscription'
require 'fake_braintree/redirect'
require 'fake_braintree/credit_card'
require 'fake_braintree/address'
require 'fake_braintree/payment_method'
require 'fake_braintree/transaction'
require 'fake_braintree/client_token'
require 'fake_braintree/credit_card_serializer'

module FakeBraintree
  class SinatraApp < Sinatra::Base
    set :show_exceptions, false
    set :dump_errors, true
    set :raise_errors, true
    set :public_folder, File.dirname(__FILE__) + '/braintree_assets'
    set :protection, except: :frame_options
    disable :logging

    include Helpers

    helpers do
      def hash_from_request_body_with_key(key)
        value = Hash.from_xml(request.body).delete(key)
        if value.is_a?(String) # This happens if there isn't actually nested data under `key`
          {}
        else
          value
        end
      end
    end

    # braintree.api.Client.prototype.tokenizeCard()
    get '/merchants/:merchant_id/client_api/v1/payment_methods/credit_cards' do
      request_hash = params

      callback = request_hash.delete('callback')
      nonce = FakeBraintree::PaymentMethod.tokenize_card(request_hash['creditCard'])

      headers = {
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'application/javascript; charset=utf-8'
      }
      json = {
        creditCards: [nonce: nonce],
        status: 201
      }.to_json
      response = "#{callback}(#{json})"
      [200, headers, gzip(response)]
    end

    # braintree.api.Client.prototype.getCreditCards()
    get '/merchants/:merchant_id/client_api/v1/payment_methods' do
      request_hash = params

      callback = request_hash.delete('callback')
      customer_id = request_hash['authorizationFingerprint']
      begin
        customer = Braintree::Customer.find(customer_id)
        credit_cards = customer.credit_cards.collect do |card|
          FakeBraintree::CreditCardSerializer.new(card).to_h
        end
      rescue Braintree::NotFoundError, ArgumentError
        credit_cards = []
      end

      headers = {
        'Content-Encoding' => 'gzip',
        'Content-Type' => 'application/javascript; charset=utf-8'
      }
      json = {
        paymentMethods: credit_cards,
        status: 200
      }.to_json
      response = "#{callback}(#{json})"
      [200, headers, gzip(response)]
    end

    # Braintree::Customer.create
    post '/merchants/:merchant_id/customers' do
      customer_hash = hash_from_request_body_with_key('customer')
      options = {merchant_id: params[:merchant_id]}
      Customer.new(customer_hash, options).create
    end

    # Braintree::Customer.find
    get '/merchants/:merchant_id/customers/:id' do
      customer = FakeBraintree.registry.customers[params[:id]]
      if customer
        gzipped_response(200, customer.to_xml(root: 'customer'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Customer.update
    put '/merchants/:merchant_id/customers/:id' do
      customer_hash = hash_from_request_body_with_key('customer')
      options = {id: params[:id], merchant_id: params[:merchant_id]}
      Customer.new(customer_hash, options).update
    end

    # Braintree::Customer.delete
    delete '/merchants/:merchant_id/customers/:id' do
      customer_hash = {}
      options = {id: params[:id], merchant_id: params[:merchant_id]}
      Customer.new(customer_hash, options).delete
    end

    # Braintree::Address.create
    post "/merchants/:merchant_id/customers/:customer_id/addresses" do
      address_hash = hash_from_request_body_with_key('address')
      options = {customer_id: params[:customer_id], merchant_id: params[:merchant_id]}
      Address.new(address_hash, options).create
    end

    # Braintree::Subscription.create
    post '/merchants/:merchant_id/subscriptions' do
      subscription_hash = hash_from_request_body_with_key('subscription')
      options = {merchant_id: params[:merchant_id]}
      Subscription.new(subscription_hash, options).create
    end

    # Braintree::Subscription.find
    get '/merchants/:merchant_id/subscriptions/:id' do
      subscription = FakeBraintree.registry.subscriptions[params[:id]]
      if subscription
        gzipped_response(200, subscription.to_xml(root: 'subscription'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Subscription.update
    put '/merchants/:merchant_id/subscriptions/:id' do
      subscription_hash = hash_from_request_body_with_key('subscription')
      options = {id: params[:id], merchant_id: params[:merchant_id]}
      Subscription.new(subscription_hash, options).update
    end

    # Braintree::Subscription.cancel
    put '/merchants/:merchant_id/subscriptions/:id/cancel' do
      options = {id: params[:id], merchant_id: params[:merchant_id]}
      Subscription.new({}, options).cancel
    end

    # Braintree::PaymentMethod.find
    get '/merchants/:merchant_id/payment_methods/any/:token' do
      credit_card = FakeBraintree.registry.credit_cards[params[:token]]
      if credit_card
        gzipped_response(200, credit_card.to_xml(root: 'credit_card'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::PaymentMethod.update
    put '/merchants/:merchant_id/payment_methods/any/:token' do
      credit_card = FakeBraintree.registry.credit_cards[params[:token]]
      updates     = hash_from_request_body_with_key('payment_method')
      options     = {token: params[:token], merchant_id: params[:merchant_id]}

      CreditCard.new(updates, options).update
    end

    # Braintree::CreditCard.find
    get '/merchants/:merchant_id/payment_methods/credit_card/:credit_card_token' do
      credit_card = FakeBraintree.registry.credit_cards[params[:credit_card_token]]
      if credit_card
        gzipped_response(200, credit_card.to_xml(root: 'credit_card'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::CreditCard.update
    put '/merchants/:merchant_id/payment_methods/credit_card/:credit_card_token' do
      credit_card = FakeBraintree.registry.credit_cards[params[:credit_card_token]]
      updates     = hash_from_request_body_with_key('credit_card')
      options     = {token: params[:credit_card_token], merchant_id: params[:merchant_id]}

      CreditCard.new(updates, options).update
    end

    # Braintree::CreditCard.delete
    delete '/merchants/:merchant_id/payment_methods/credit_card/:credit_card_token' do
      cc_hash     = {}
      options     = {token: params[:credit_card_token], merchant_id: params[:merchant_id]}

      CreditCard.new(cc_hash, options).delete
    end

    # Braintree::PaymentMethod.create
    # Braintree::CreditCard.create
    post '/merchants/:merchant_id/payment_methods' do
      request_hash = Hash.from_xml(request.body)
      request.body.rewind

      credit_card_hash =
        if request_hash.key?('credit_card')
          hash_from_request_body_with_key('credit_card')
        else
          payment_method_hash = hash_from_request_body_with_key('payment_method')
          nonce = payment_method_hash.delete('payment_method_nonce')
          FakeBraintree.registry.payment_methods[nonce].merge(payment_method_hash)
        end
      options = {merchant_id: params[:merchant_id]}

      if credit_card_hash['options']
        options.merge!(credit_card_hash.delete('options')).symbolize_keys!
      end

      CreditCard.new(credit_card_hash, options).create
    end

    # Braintree::Transaction.sale
    # Braintree::CreditCard.sale
    post '/merchants/:merchant_id/transactions' do
      if FakeBraintree.decline_all_cards?
        gzipped_response(422, FakeBraintree.create_failure.to_xml(root: "api_error_response"))
      else
        data = hash_from_request_body_with_key("transaction")
        transaction_id = md5("#{params[:merchant_id]}#{Time.now.to_f}")
        transaction = FakeBraintree::Transaction.new(data, transaction_id)
        response = transaction.create
        gzipped_response(200, response.to_xml(root: "transaction"))
      end
    end

    # Braintree::Transaction.find
    get '/merchants/:merchant_id/transactions/:transaction_id' do
      transaction = FakeBraintree.registry.transactions[params[:transaction_id]]
      if transaction
        gzipped_response(200, transaction.to_xml(root: 'transaction'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Transaction.refund
    post '/merchants/:merchant_id/transactions/:transaction_id/refund' do
      transaction          = hash_from_request_body_with_key('transaction')
      transaction_id       = md5("#{params[:merchant_id]}#{Time.now.to_f}")
      transaction_response = {'id' => transaction_id, 'amount' => transaction['amount'], 'type' => 'credit'}
      FakeBraintree.registry.transactions[transaction_id] = transaction_response
      gzipped_response(200, transaction_response.to_xml(root: 'transaction'))
    end

    # Braintree:Transaction.submit_for_settlement
    put '/merchants/:merchant_id/transactions/:transaction_id/submit_for_settlement' do
      transaction = FakeBraintree.registry.transactions[params[:transaction_id]]
      transaction_response = {'id' => transaction['id'],
                              'type' => transaction['sale'],
                              'amount' => transaction['amount'],
                              'status' => Braintree::Transaction::Status::SubmittedForSettlement}
      FakeBraintree.registry.transactions[transaction['id']] = transaction_response
      gzipped_response(200, transaction_response.to_xml(root: 'transaction'))
    end

    # Braintree::Transaction.void
    put '/merchants/:merchant_id/transactions/:transaction_id/void' do
      transaction = FakeBraintree.registry.transactions[params[:transaction_id]]
      transaction_response = {'id' => transaction['id'],
                              'type' => transaction['sale'],
                              'amount' => transaction['amount'],
                              'status' => Braintree::Transaction::Status::Voided}
      FakeBraintree.registry.transactions[transaction['id']] = transaction_response
      gzipped_response(200, transaction_response.to_xml(root: 'transaction'))
    end

    # Braintree::TransparentRedirect.url
    post '/merchants/:merchant_id/transparent_redirect_requests' do
      if params[:tr_data]
        redirect = Redirect.new(params, params[:merchant_id])
        FakeBraintree.registry.redirects[redirect.id] = redirect
        redirect to(redirect.url), 303
      else
        [422, { 'Content-Type' => 'text/html' }, ['Invalid submission']]
      end
    end

    # Braintree::TransparentRedirect.confirm
    post '/merchants/:merchant_id/transparent_redirect_requests/:id/confirm' do
      redirect = FakeBraintree.registry.redirects[params[:id]]
      redirect.confirm
    end

    # Braintree::ClientToken.generate
    post '/merchants/:merchant_id/client_token' do
      client_token_hash = hash_from_request_body_with_key('client_token')
      token = FakeBraintree::ClientToken.generate(client_token_hash)
      response = { value: token }.to_xml(root: :client_token)
      gzipped_response(200, response)
    end
  end
end
