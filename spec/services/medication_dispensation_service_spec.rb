require "rails_helper"

RSpec.describe MedicationDispensationService, type: :model do
  it "returns a hash of hashes containing key/value pairs of attributes of AppointmentsScheduledDaysDistribution for a region and a period range" do
    region = create(:facility)
    period = Period.current
    _patient = create(:patient, assigned_facility: region)
    _appointment_created_today = create(:appointment, facility: region, scheduled_date: 10.days.from_now, device_created_at: Date.today)

    RefreshReportingViews.new.refresh_v2

    medications_dispensation_service = MedicationDispensationService.new(region: region, period: period)

    expect(medications_dispensation_service.distribution.keys).to match_array(["15 - 30 days", "0 - 14 days", "31 - 60 days", "60+ days"])

    medications_dispensation_service.distribution.values.map { |bucket_data|
      expect(bucket_data.keys).to match_array([:color, :counts, :totals, :percentages])
    }
  end
end
