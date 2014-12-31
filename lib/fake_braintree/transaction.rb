module FakeBraintree
  class Transaction
    def initialize(id, amount, options)
      @id = id
      @amount = amount
      @options = options || {}
    end

    def create
      FakeBraintree.registry.transactions[@id] = response
      response
    end

    private

    def response
      {
        'id' => @id,
        'amount' => @amount,
        'status' => status,
        'type' => 'sale'
      }
    end

    def status
      if @options.fetch("submit_for_settlement", false) == true
        "submitted_for_settlement"
      else
        "authorized"
      end
    end
  end
end
