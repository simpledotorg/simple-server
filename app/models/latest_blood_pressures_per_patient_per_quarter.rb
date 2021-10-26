class LatestBloodPressuresPerPatientPerQuarter < ApplicationRecord
  extend Reports::Refreshable
  include BloodPressureable
  include PatientReportableMatview

  belongs_to :patient
end
