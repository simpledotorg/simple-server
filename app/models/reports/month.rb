# frozen_string_literal: true

module Reports
  class Month < Reports::View
    self.table_name = "reporting_months"

    def self.materialized?
      false
    end
  end
end
