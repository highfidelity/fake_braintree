require 'digest/md5'
require 'sinatra'
require 'active_support'
require 'active_support/core_ext'

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

      def verify_credit_card?(customer_hash)
        return true if FakeBraintree.verify_all_cards

        customer_hash["credit_card"].key?("options") &&
          customer_hash["credit_card"]["options"].is_a?(Hash) &&
          customer_hash["credit_card"]["options"]["verify_card"] == true
      end

      def has_invalid_credit_card?(customer_hash)
        ! FakeBraintree::VALID_CREDIT_CARDS.include?(customer_hash["credit_card"]["number"])
      end
    end

    # Braintree::Customer.create
    post "/merchants/:merchant_id/customers" do
      customer = Hash.from_xml(request.body).delete("customer")
      if FakeBraintree.failure?(customer["credit_card"]["number"])
        gzipped_response(422, FakeBraintree.failure_response(customer["credit_card"]["number"]).to_xml(:root => 'api_error_response'))
      else
        if verify_credit_card?(customer) && has_invalid_credit_card?(customer)
          gzipped_response(422, FakeBraintree.failure_response(customer["credit_card"]["number"]).to_xml(:root => 'api_error_response'))
        else
          customer["id"] ||= md5("#{params[:merchant_id]}#{Time.now.to_f}")
          customer["merchant-id"] = params[:merchant_id]
          if customer["credit_card"] && customer["credit_card"].is_a?(Hash)
            customer["credit_card"].delete("__content__")
            if !customer["credit_card"].empty?
              customer["credit_card"]["last_4"]           = customer["credit_card"].delete("number")[-4..-1]
              customer["credit_card"]["token"]            = md5("#{customer['merchant_id']}#{customer['id']}#{Time.now.to_f}")
              expiration_date = customer["credit_card"].delete("expiration_date")
              customer["credit_card"]["expiration_month"] = expiration_date.split('/')[0]
              customer["credit_card"]["expiration_year"]  = expiration_date.split('/')[1]

              credit_card = customer.delete("credit_card")
              customer["credit_cards"] = [credit_card]
            end
          end
          FakeBraintree.customers[customer["id"]] = customer
          gzipped_response(201, customer.to_xml(:root => 'customer'))
        end
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
      FakeBraintree.customers[params["id"]] = nil
      gzipped_response(200, "")
    end

    # Braintree::Subscription.create
    post "/merchants/:merchant_id/subscriptions" do
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<subscription>\n  <plan-id type=\"integer\">2</plan-id>\n  <payment-method-token>b22x</payment-method-token>\n</subscription>\n"
      subscription = Hash.from_xml(request.body).delete("subscription")
      subscription["id"]                ||= md5("#{subscription["payment_method_token"]}#{Time.now.to_f}")[0,6]
      subscription["transactions"]      = []
      subscription["add_ons"]           = []
      subscription["discounts"]         = []
      subscription["next_billing_date"] = 1.month.from_now
      subscription["status"]            = Braintree::Subscription::Status::Active
      FakeBraintree.subscriptions[subscription["id"]] = subscription
      gzipped_response(201, subscription.to_xml(:root => 'subscription'))
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
      # "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<search>\n  <ids type=\"array\">\n    <item>49sbx6</item>\n  </ids>\n  <created-at>\n    <min type=\"datetime\">2011-01-10T14:14:26Z</min>\n  </created-at>\n</search>\n"
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
