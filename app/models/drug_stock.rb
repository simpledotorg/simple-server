class DrugStock < ApplicationRecord
  belongs_to :facility
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true

  def self.latest_for_facilities_grouped_by_protocol_drug(facilities, end_of_month)
    drug_stock_list = latest_for_facilities(facilities, end_of_month) || []
    drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  def self.latest_for_facilities(facilities, for_end_of_month)
    select("DISTINCT ON (facility_id, protocol_drug_id) *")
      .includes(:protocol_drug)
      .where(facility_id: facilities, for_end_of_month: for_end_of_month)
      .order(:facility_id, :protocol_drug_id, created_at: :desc)
  end

  def self.latest_for_facilities_cte(facilities, for_end_of_month)
    # This is needed to do GROUP queries which do not compose with DISTINCT ON
    from(latest_for_facilities(facilities, for_end_of_month), table_name)
  end

  def self.latest_for_facility(facility, for_end_of_month)
    latest_for_facilities([facility], for_end_of_month)
  end

  def self.with_protocol_drug_data
    includes(facility: {facility_group: :protocol})
      .includes(:protocol_drug)
  end
end
