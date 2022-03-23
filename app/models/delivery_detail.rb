class DeliveryDetail < ApplicationRecord
  self.abstract_class = true
  has_one :communication, as: :detailable

  def successful?
    raise NotImplementedError
  end

  def unsuccessful?
    raise NotImplementedError
  end

  def in_progress?
    raise NotImplementedError
  end
end
