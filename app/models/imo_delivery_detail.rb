class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {

  }

  # this might be better as a service object
  class << self
    def create(response)
      parse_notification_response()
      new()
    end

    protected

    def parse_notification_response(response)
    end
  end
end