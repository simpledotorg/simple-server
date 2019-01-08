class Protocol < ApplicationRecord
  has_many :protocol_drugs

  has_many :facility_groups

  before_create :assign_id

  validates :name, presence: true
  validates :follow_up_days, numericality: true, presence: true

  def assign_id
    self.id = SecureRandom.uuid
  end
end
