class DrugStock < ApplicationRecord
  belongs_to :facility
  belongs_to :region, optional: true
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
      .includes(:protocol_drug)
  end

  def self.with_block_region_id
    joins("INNER JOIN reporting_facilities on drug_stocks.facility_id = reporting_facilities.facility_id")
      .select("reporting_facilities.block_region_id as block_region_id, drug_stocks.*")
  end
end
