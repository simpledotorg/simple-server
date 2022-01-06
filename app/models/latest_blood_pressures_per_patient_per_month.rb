# frozen_string_literal: true

class LatestBloodPressuresPerPatientPerMonth < ApplicationRecord
  extend Reports::Refreshable
  include BloodPressureable
  include PatientReportableMatview

  belongs_to :patient
  belongs_to :medical_history, primary_key: :patient_id, foreign_key: :patient_id
  belongs_to :facility, class_name: "Facility", foreign_key: "bp_facility_id"
end
