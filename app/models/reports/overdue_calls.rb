module Reports
  class OverdueCalls < Reports::View
    self.table_name = "reporting_overdue_calls"

    def self.materialized?
      true
    end
  end
end
