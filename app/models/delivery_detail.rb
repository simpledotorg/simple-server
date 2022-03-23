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

  # This should create the delivery detail, create an
  # associated communication and return the communication object.
  def self.create_with_communication!
    raise NotImplementedError
  end
end
