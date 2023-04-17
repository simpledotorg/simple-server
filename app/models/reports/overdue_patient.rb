module Reports
  class OverduePatient < Reports::View
    self.table_name = "reporting_overdue_patients"

    def self.materialized?
      true
    end
  end
end
