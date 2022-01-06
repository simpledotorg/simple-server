# frozen_string_literal: true

module PatientDeduplicationHelper
  def no_difference_class(records)
    "alert-success" if records.uniq.count == 1
  end
end
