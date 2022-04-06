module Reports
  class PatientBloodSugar < Reports::View
    self.table_name = "reporting_patient_blood_sugars"
    belongs_to :patient

    enum blood_sugar_risk_state: {
      bs_below_200: "bs_below_200",
      bs_200_to_299: "bs_200_to_299",
      bs_over_299: "bs_over_299"
    }

    def self.materialized?
      true
    end
  end
end
