require 'sinatra/base'

module FakeBraintree
  class SinatraApp < Sinatra::Base
    set :show_exceptions, false
    set :dump_errors, true
    set :raise_errors, true
    disable :logging

    helpers do
      def gzip(content)
        ActiveSupport::Gzip.compress(content)
      end

      def gzipped_response(status_code, uncompressed_content)
        [status_code, { "Content-Encoding" => "gzip" }, gzip(uncompressed_content)]
      end

      def md5(content)
        Digest::MD5.hexdigest(content)
      end
    end

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

    get "/merchants/:merchant_id/customers/:id" do
      customer = FakeBraintree.customers[params[:id]]
      gzipped_response(200, customer.to_xml(:root => 'customer'))
    end

    put "/merchants/:merchant_id/customers/:id" do
      customer = Hash.from_xml(request.body).delete("customer")
      if FakeBraintree.failure?(customer["credit_card"]["number"])
        gzipped_response(422, FakeBraintree.failure_response(customer["credit_card"]["number"]).to_xml(:root => 'api_error_response'))
      else
        customer["id"]          = params[:id]
        customer["merchant-id"] = params[:merchant_id]
        if customer["credit_card"] && customer["credit_card"].is_a?(Hash)
          customer["credit_card"].delete("__content__")
          if !customer["credit_card"].empty?
            customer["credit_card"]["last_4"] = customer["credit_card"].delete("number")[-4..-1]
            customer["credit_card"]["token"]  = md5("#{customer['merchant_id']}#{customer['id']}#{Time.now.to_f}")
            credit_card = customer.delete("credit_card")
            customer["credit_cards"] = [credit_card]
          end
        end
        FakeBraintree.customers[params["id"]] = customer
        gzipped_response(200, customer.to_xml(:root => 'customer'))
      end
    end

    delete "/merchants/:merchant_id/customers/:id" do
      FakeBraintree.customers[params[:id]] = nil
      gzipped_response(200, "")
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

    put "/merchants/:merchant_id/subscriptions/:id" do
      subscription = Hash.from_xml(request.body).delete("subscription")
      subscription["transactions"] = []
      subscription["add_ons"]      = []
      subscription["discounts"]    = []
      FakeBraintree.subscriptions[params["id"]] = subscription
      gzipped_response(200, subscription.to_xml(:root => 'subscription'))
    end

    # Braintree::Transaction.search
    post "/merchants/:merchant_id/transactions/advanced_search_ids" do
      # "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<search>\n  <created-at>\n    <min type=\"datetime\">2011-01-10T14:14:26Z</min>\n  </created-at>\n</search>\n"
      gzipped_response(200,
                       ['<search-results>',
                        '  <page-size type="integer">50</page-size>',
                        '  <ids type="array">',
                        '          <item>49sbx6</item>',
                        '      </ids>',
                        "</search-results>\n"].join("\n"))
    end

    # Braintree::Transaction.search
    post "/merchants/:merchant_id/transactions/advanced_search" do
      gzipped_response(200, FakeBraintree.generated_transaction.to_xml)
    end

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
