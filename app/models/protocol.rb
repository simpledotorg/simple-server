class Protocol < ApplicationRecord
  has_many :protocol_drugs

  has_many :facility_groups

  before_create :assign_id

  validates :name, presence: true
  validates :follow_up_days, numericality: true, presence: true

  auto_strip_attributes :name, squish: true, upcase_first: true

  def as_json
    sorted_protocol_drugs = protocol_drugs.sort_by { |protocol_drug| [protocol_drug.name, protocol_drug.dosage.to_i] }
    protocol_json = super
    protocol_json["protocol_drugs"] = sorted_protocol_drugs.map { |protocol_drug| protocol_drug.as_json }
    protocol_json
  end

  def assign_id
    self.id = SecureRandom.uuid
  end
end
