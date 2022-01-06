# frozen_string_literal: true

module Reports
  class Facility < Reports::View
    self.table_name = "reporting_facilities"

    def self.materialized?
      false
    end
  end
end
