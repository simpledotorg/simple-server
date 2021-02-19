class DrugStock < ApplicationRecord
  belongs_to :facility
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true

  def self.latest_for_facilities(facilities, for_end_of_month)
    DrugStock.select("DISTINCT ON (facility_id, protocol_drug_id) *")
      .includes(:protocol_drug)
      .where(facility_id: facilities, for_end_of_month: for_end_of_month)
      .order(:facility_id, :protocol_drug_id, created_at: :desc)
  end

  def self.latest_for_facility(facility, for_end_of_month)
    latest_for_facilities([facility], for_end_of_month)
  end
end
