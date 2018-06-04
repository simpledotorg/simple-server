class Protocol < ApplicationRecord

  before_create :assign_id

  def assign_id
    self.id = SecureRandom.uuid
  end
end
