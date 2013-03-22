require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context 'Braintree::TransparentRedirect.url' do
    it 'returns a URL that will redirect with a token for the specified request' do
      redirect_url = 'http://example.com/redirect_path'

      response = post_transparent_redirect(:redirect_url => redirect_url, :customer => build_customer_hash)

      response.code.should == '303'
      response['Location'].should =~ %r{http://example\.com/redirect_path}
      params = parse_redirect(response)
      params[:http_status].should == '200'
      params[:id].should_not be_nil
      params[:kind].should_not be_nil
    end

    it 'rejects submissions without transparent redirect data' do
      response = post_transparent_redirect_without_data
      response.code.should == '422'
    end
  end

  context 'Braintree::TransparentRedirect.confirm' do
    it 'confirms and runs the specified request' do
      number = '4111111111111111'
      customer_hash = build_customer_hash(:credit_card => { :number => number })
      response = post_transparent_redirect(:customer => customer_hash)
      query = parse_query(response)

      result = Braintree::TransparentRedirect.confirm(query)

      result.should be_success

      customer = Braintree::Customer.find(result.customer.id)
      customer.credit_cards.first.last_4.should == '1111'
    end
  end

  def build_customer_hash(options = {})
    {
      :credit_card => {
        :number => '4111111111111111',
        :expiration_date => '4/2015',
        :cardholder_name => 'Susie Spender'
      }.update(options[:credit_card] || {})
    }
  end

  def post_transparent_redirect(data)
    params = data.dup
    redirect_url = params.delete(:redirect_url) || 'http://example.com/redirect_path'
    params[:tr_data] = Braintree::TransparentRedirect.create_customer_data(:redirect_url => redirect_url)
    post_transparent_redirect_params(params)
  end

  def post_transparent_redirect_without_data
    post_transparent_redirect_params({})
  end

  def post_transparent_redirect_params(params)
    uri = URI.parse(Braintree::TransparentRedirect.url)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.post(uri.path, Rack::Utils.build_nested_query(params))
    end
  end

  def parse_redirect(response)
    query = parse_query(response)
    Braintree::Configuration.gateway.transparent_redirect.parse_and_validate_query_string(query)
  end

  def parse_query(response)
    URI.parse(response['Location']).query
  end
end
