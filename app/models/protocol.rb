# frozen_string_literal: true

class Protocol < ApplicationRecord
  has_many :protocol_drugs

  has_many :facility_groups

  before_create :assign_id

  validates :name, presence: true
  validates :follow_up_days, numericality: true, presence: true

  auto_strip_attributes :name, squish: true, upcase_first: true

  def as_json
    super.tap do |json|
      json["protocol_drugs"] = protocol_drugs.sort_by(&:sort_key).map(&:as_json)
    end
  end

  def assign_id
    self.id = SecureRandom.uuid
  end
end
