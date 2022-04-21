module Reports
  class PatientBloodSugar < Reports::View
    self.table_name = "reporting_patient_blood_sugars"
    belongs_to :patient

    enum blood_sugar_risk_state: {
      bs_below_200: "bs_below_200",
      bs_200_to_300: "bs_200_to_300",
      bs_over_300: "bs_over_300"
    }

    def self.materialized?
      true
    end
  end
end
