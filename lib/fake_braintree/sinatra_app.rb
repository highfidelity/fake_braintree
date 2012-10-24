require 'sinatra/base'

module FakeBraintree
  class SinatraApp < Sinatra::Base
    set :show_exceptions, false
    set :dump_errors, true
    set :raise_errors, true
    disable :logging

    include Helpers

    helpers do
      def hash_from_request_body_with_key(request, key)
        Hash.from_xml(request.body).delete(key)
      end
    end

    # Braintree::Customer.create
    post "/merchants/:merchant_id/customers" do
      customer_hash = hash_from_request_body_with_key(request, "customer")
      options = {:merchant_id => params[:merchant_id]}
      Customer.new(customer_hash, options).create
    end

    # Braintree::Customer.find
    get "/merchants/:merchant_id/customers/:id" do
      customer = FakeBraintree.registry.customers[params[:id]]
      if customer
        gzipped_response(200, customer.to_xml(:root => 'customer'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Customer.update
    put "/merchants/:merchant_id/customers/:id" do
      customer_hash = hash_from_request_body_with_key(request, "customer")
      options = {:id => params[:id], :merchant_id => params[:merchant_id]}
      Customer.new(customer_hash, options).update
    end

    # Braintree::Customer.delete
    delete "/merchants/:merchant_id/customers/:id" do
      customer_hash = {}
      options = {:id => params[:id], :merchant_id => params[:merchant_id]}
      Customer.new(customer_hash, options).delete
    end

    # Braintree::Subscription.create
    post "/merchants/:merchant_id/subscriptions" do
      subscription_hash = hash_from_request_body_with_key(request, "subscription")
      options = {:merchant_id => params[:merchant_id]}
      Subscription.new(subscription_hash, options).create
    end

    # Braintree::Subscription.find
    get "/merchants/:merchant_id/subscriptions/:id" do
      subscription = FakeBraintree.registry.subscriptions[params[:id]]
      if subscription
        gzipped_response(200, subscription.to_xml(:root => 'subscription'))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Subscription.update
    put "/merchants/:merchant_id/subscriptions/:id" do
      subscription_hash = hash_from_request_body_with_key(request, "subscription")
      options = {:id => params[:id], :merchant_id => params[:merchant_id]}
      Subscription.new(subscription_hash, options).update
    end

    # Braintree::Subscription.cancel
    put "/merchants/:merchant_id/subscriptions/:id/cancel" do
      updates = {"status" => Braintree::Subscription::Status::Canceled}
      options = {:id => params[:id], :merchant_id => params[:merchant_id]}
      Subscription.new(updates, options).update
    end

    # Braintree::CreditCard.find
    get "/merchants/:merchant_id/payment_methods/:credit_card_token" do
      credit_card = FakeBraintree.registry.credit_cards[params[:credit_card_token]]
      gzipped_response(200, credit_card.to_xml(:root => "credit_card"))
    end

    post "/merchants/:merchant_id/payment_methods" do
      opts = {
        :token => md5("#{Time.now}#{rand}"),
        :merchant_id => params[:merchant_id]
      }
      data = hash_from_request_body_with_key(request, 'credit_card')
      if data[:token]
        opts[:token] = data[:token]
      end
      credit_card = CreditCard.new(data, opts)
      FakeBraintree.registry.credit_cards[opts[:token]] = credit_card
      gzipped_response(200, credit_card.to_xml)
    end

    # Braintree::CreditCard.update
    put "/merchants/:merchant_id/payment_methods/:credit_card_token" do
      credit_card = FakeBraintree.registry.credit_cards[params[:credit_card_token]]
      updates     = hash_from_request_body_with_key(request, "credit_card")
      options     = {:token => params[:credit_card_token], :merchant_id => params[:merchant_id]}
      CreditCard.new(updates, options).update
    end

    # Braintree::Transaction.sale
    # Braintree::CreditCard.sale
    post "/merchants/:merchant_id/transactions" do
      if FakeBraintree.decline_all_cards?
        gzipped_response(422, FakeBraintree.create_failure.to_xml(:root => 'api_error_response'))
      else
        transaction          = hash_from_request_body_with_key(request, "transaction")
        transaction_id       = md5("#{params[:merchant_id]}#{Time.now.to_f}")
        options              = transaction["options"] || {}
        status               = "authorized"
        if options.fetch("submit_for_settlement", false) == true
          status           = "submitted_for_settlement"
        end
        transaction_response = {"id" => transaction_id, "amount" => transaction["amount"], "status" => status}
        FakeBraintree.registry.transactions[transaction_id] = transaction_response
        gzipped_response(200, transaction_response.to_xml(:root => "transaction"))
      end
    end

    # Braintree::Transaction.find
    get "/merchants/:merchant_id/transactions/:transaction_id" do
      transaction = FakeBraintree.registry.transactions[params[:transaction_id]]
      if transaction
        gzipped_response(200, transaction.to_xml(:root => "transaction"))
      else
        gzipped_response(404, {})
      end
    end

    # Braintree::Transaction.refund
    # Braintree::CreditCard.refund
    post "/merchants/:merchant_id/transactions/:transaction_id/refund" do
      if FakeBraintree.decline_all_cards?
        gzipped_response(422, FakeBraintree.create_failure.to_xml(:root => 'api_error_response'))
      else
        transaction          = hash_from_request_body_with_key(request, "transaction")
        transaction_id       = md5("#{params[:merchant_id]}#{Time.now.to_f}")
        transaction_response = {"id" => transaction_id, "amount" => transaction["amount"], "type" => "credit"}
        FakeBraintree.registry.transactions[transaction_id] = transaction_response
        gzipped_response(200, transaction_response.to_xml(:root => "transaction"))
      end
    end

    # Braintree::TransparentRedirect.url
    post "/merchants/:merchant_id/transparent_redirect_requests" do
      if params[:tr_data]
        redirect = Redirect.new(params, params[:merchant_id])
        FakeBraintree.registry.redirects[redirect.id] = redirect
        redirect to(redirect.url), 303
      else
        [422, { "Content-Type" => "text/html" }, ["Invalid submission"]]
      end
    end

    # Braintree::TransparentRedirect.confirm
    post "/merchants/:merchant_id/transparent_redirect_requests/:id/confirm" do
      redirect = FakeBraintree.registry.redirects[params[:id]]
      redirect.confirm
    end
  end
end
