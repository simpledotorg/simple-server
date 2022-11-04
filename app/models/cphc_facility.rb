class CphcFacility < ApplicationRecord
  include PgSearch::Model

  belongs_to :facility, optional: true
  has_many :cphc_facility_villages

  pg_search_scope :search_by_facility_name,
    against: :cphc_facility_name,
    using: {tsearch: {any_word: true, prefix: true}}

  pg_search_scope :search_by_region, against: {
    cphc_district_name: "A",
    cphc_taluka_name: "B"
  }, using: {tsearch: {any_word: true, prefix: true}}

  def self.copy_phcs_from_mapping
    CphcFacilityMapping.select("DISTINCT ON(cphc_phc_id) *").each do |mapping|
      CphcFacility.find_or_create_by!(cphc_facility_id: mapping.cphc_phc_id) do |facility|
        facility.facility_id = mapping.facility_id
        facility.cphc_facility_id = mapping.cphc_phc_id
        facility.cphc_facility_name = mapping.cphc_phc_name
        facility.cphc_district_id = mapping.cphc_district_id
        facility.cphc_district_name = mapping.cphc_district_name
        facility.cphc_taluka_id = mapping.cphc_taluka_id
        facility.cphc_taluka_name = mapping.cphc_taluka_id
        facility.cphc_state_name = mapping.cphc_state_name
        facility.cphc_state_id = mapping.cphc_state_id
        facility.cphc_user_details = mapping.cphc_user_details
        facility.cphc_facility_type = "PHC"
        facility.cphc_facility_type_id = OneOff::CphcEnrollment::FACILITY_TYPE_ID["PHC"]
      end
    end

    CphcFacilityMapping.select("DISTINCT ON(cphc_subcenter_id) *").each do |mapping|
      CphcFacility.find_or_create_by!(cphc_facility_id: mapping.cphc_subcenter_id) do |facility|
        facility.facility_id = nil
        facility.cphc_facility_id = mapping.cphc_subcenter_id
        facility.cphc_facility_name = mapping.cphc_subcenter_name
        facility.cphc_district_id = mapping.cphc_district_id
        facility.cphc_district_name = mapping.cphc_district_name
        facility.cphc_taluka_id = mapping.cphc_taluka_id
        facility.cphc_taluka_name = mapping.cphc_taluka_id
        facility.cphc_state_name = mapping.cphc_state_name
        facility.cphc_state_id = mapping.cphc_state_id
        facility.cphc_user_details = nil
        facility.cphc_facility_type = "SUBCENTER"
        facility.cphc_facility_type_id = OneOff::CphcEnrollment::FACILITY_TYPE_ID["SUBCENTER"]
      end
    end
  end
end
