class ImoDeliveryDetail < ApplicationRecord
  has_one :communication, as: :detailable

  enum result: {
    
  }
end