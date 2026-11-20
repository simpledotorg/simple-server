module Reports
  class Prescription < Reports::View
    self.table_name = "reporting_prescriptions"
    belongs_to :patient

    def self.materialized?
      false
    end

    def self.partitioned?
      true
    end
  end
end
