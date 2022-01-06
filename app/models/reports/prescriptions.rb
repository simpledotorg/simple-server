# frozen_string_literal: true

module Reports
  class Prescriptions < Reports::View
    self.table_name = "reporting_prescriptions"
    belongs_to :patient

    def self.materialized?
      true
    end
  end
end
