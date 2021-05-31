class DrugStock < ApplicationRecord
  belongs_to :facility, optional: true
  belongs_to :region
  belongs_to :user
  belongs_to :protocol_drug

  validates :in_stock, numericality: true, allow_nil: true
  validates :received, numericality: true, allow_nil: true
  validates :for_end_of_month, presence: true
  validate :facility_or_region

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

  def self.latest_for_facility(facility, for_end_of_month)
    latest_for_facilities([facility], for_end_of_month)
  end

  def self.latest_for_regions_grouped_by_protocol_drug(regions, end_of_month)
    drug_stock_list = latest_for_regions(regions, end_of_month) || []
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

  def self.latest_for_region(region, for_end_of_month)
    latest_for_regions([region], for_end_of_month)
  end

  def facility_or_region
    facility || region
  end
end
