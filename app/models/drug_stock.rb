class DrugStock < ApplicationRecord
  belongs_to :facility, optional: true
  belongs_to :region
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true

  scope :with_region_information, -> {
    joins("INNER JOIN reporting_facilities on drug_stocks.facility_id = reporting_facilities.facility_id")
      .select("reporting_facilities.*, drug_stocks.*")
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

  def +(other)
    raise "what you cant do this" if for_end_of_month != other.for_end_of_month || protocol_drug_id != other.protocol_drug_id

    DrugStock.new(
      for_end_of_month: for_end_of_month,
      protocol_drug_id: protocol_drug_id,
      in_stock: in_stock.to_i + other.in_stock.to_i,
      received: received.to_i + other.received.to_i,
      redistributed: redistributed.to_i + other.redistributed.to_i
    )
  end
end
