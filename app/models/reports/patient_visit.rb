# frozen_string_literal: true

module Reports
  class PatientVisit < Reports::View
    self.table_name = "reporting_patient_visits"
    belongs_to :patient

    def self.materialized?
      true
    end
  end
end
