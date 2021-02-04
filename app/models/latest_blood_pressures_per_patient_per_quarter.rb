class LatestBloodPressuresPerPatientPerQuarter < ApplicationRecord
  include BloodPressureable
  include PatientReportableMatview

  belongs_to :patient
end
