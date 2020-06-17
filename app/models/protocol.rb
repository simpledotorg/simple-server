class Protocol < ApplicationRecord
  has_many :protocol_drugs, -> { order(:updated_at) }

  has_many :facility_groups

  before_create :assign_id

  validates :name, presence: true
  validates :follow_up_days, numericality: true, presence: true

  auto_strip_attributes :name, squish: true, upcase_first: true

  def assign_id
    self.id = SecureRandom.uuid
  end
end
