class DrugStock < ApplicationRecord
  belongs_to :facility
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true

  def self.latest_for_facility(facility, for_end_of_month)
    DrugStock.select("DISTINCT ON (protocol_drug_id) *")
      .where(facility_id: facility.id, for_end_of_month: for_end_of_month)
      .order(:protocol_drug_id, created_at: :desc)
  end
end
