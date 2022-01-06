# frozen_string_literal: true

module Reports
  class PatientBloodPressure < Reports::View
    self.table_name = "reporting_patient_blood_pressures"
    belongs_to :patient

    def self.materialized?
      true
    end
  end
end
