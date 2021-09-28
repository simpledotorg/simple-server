class LatestBloodPressuresPerPatient < ApplicationRecord
  extend Reports::Refreshable
  include BloodPressureable
  include PatientReportableMatview

  belongs_to :patient
  belongs_to :bp_facility, class_name: "Facility", foreign_key: :bp_facility_id
  belongs_to :registration_facility, class_name: "Facility", foreign_key: :registration_facility_id
end
