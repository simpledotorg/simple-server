class DrugStock < ApplicationRecord
  belongs_to :facility, optional: true
  belongs_to :region
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true

  scope :with_region_information, -> {
    select("block_regions.name AS block_region_name, block_regions.id AS block_region_id, drug_stocks.*")
      .joins("INNER JOIN regions AS facility_regions ON drug_stocks.facility_id = facility_regions.source_id
           INNER JOIN regions AS block_regions ON block_regions.path = subpath(facility_regions.path, 0, - 1)")
  }

  def self.latest_for_facilities_grouped_by_protocol_drug(facilities, end_of_month)
    drug_stock_list = latest_for_facilities(facilities, end_of_month) || []
    drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  def self.latest_for_regions_grouped_by_protocol_drug(region, end_of_month)
    drug_stock_list = latest_for_regions(region, end_of_month) || []
    drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  def self.latest_for_regions(regions, for_end_of_month)
    select("DISTINCT ON (region_id, protocol_drug_id) *")
      .includes(:protocol_drug)
      .where(region_id: regions, for_end_of_month: for_end_of_month)
      .order(:region_id, :protocol_drug_id, created_at: :desc)
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

  def self.latest_for_regions_cte(regions, for_end_of_month)
    # This is needed to do GROUP queries which do not compose with DISTINCT ON
    from(latest_for_regions(regions, for_end_of_month), table_name)
      .includes(:protocol_drug)
  end
end
