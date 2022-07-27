require "csv"

class CPHCEnrollment::RandomLocationFinder
  CPHC_FACILITIES_CSV_FILE = "./sample_cphc_facilities.csv"
  SIMPLE_FACILITIES_CSV_FILE = "./sample_simple_facilities.csv"

  attr_reader :cphc_facility_hashes, :simple_facility_hashes, :current_mapping
  def initialize(cphc_facility_hashes, simple_facility_hashes)
    @cphc_facility_hashes = cphc_facility_hashes
    @simple_facility_hashes = simple_facility_hashes
    @current_mapping = {}
  end

  def self.build
    cphc_facility_hashes = CSV.read(CPHC_FACILITIES_CSV_FILE, headers: true).map(&:to_h)
    simple_facility_hashes = CSV.read(SIMPLE_FACILITIES_CSV_FILE, headers: true).map(&:to_h)
    new(cphc_facility_hashes, simple_facility_hashes)
  end

  def find_cphc_location(simple_location)
    throw "Can only use facility_name or village_name" unless simple_location.keys.all? { |k| %w[facility_name village_or_colony].include?(k) }
    simple_facility_hash = simple_facility_hashes.find { |h| simple_location.entries.map { |k, v| h[k] == v }.all? }
    throw "Unknown simple facility" unless simple_facility_hash.present?
    if @current_mapping[simple_facility_hash].present?
      @current_mapping[simple_facility_hash]
    else
      throw "All CPHC Facilities exhausted" if cphc_facility_hashes.empty?
      result = cphc_facility_hashes.sample
      @current_mapping[simple_facility_hash] = result
      cphc_facility_hashes.delete result
    end
  end

  def simple_facility(id)
    simple_facility_hashes.find { |h| h["facility_id"] = id }
  end
end
