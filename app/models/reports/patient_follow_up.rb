module Reports
  class PatientFollowUp < Reports::View
    self.table_name = "reporting_patient_follow_ups"
    belongs_to :patient
    belongs_to :facility, class_name: "::Facility"
    belongs_to :user

    def self.materialized?
      true
    end
  end
end
