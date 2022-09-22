require "rails_helper"

RSpec.describe Reports::ProgressControlComponent, type: :component do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "returns the summary of control stats for the previous month" do
    Timecop.freeze("February 1st 2022") do
      patients = [create(:patient, :hypertension, registration_facility: facility, recorded_at: 6.months.ago, gender: "female"),
        create(:patient, :hypertension, registration_facility: facility, recorded_at: 6.months.ago, gender: "male"),
        create(:patient, :diabetes, registration_facility: facility, recorded_at: 6.months.ago, gender: "transgender")]

      patients.each do |patient|
        create(:blood_pressure, :with_encounter, :critical, patient: patient, facility: facility, user: user, recorded_at: 3.months.ago)
        create(:blood_pressure, :under_control, patient: patient, facility: facility, user: user, recorded_at: 2.month.ago)
      end
      refresh_views
      service = Reports::FacilityProgressService.new(facility, Period.current)
      component = described_class.new(service, user)
      expect(component.control_summary).to eq("2 of 2 patients")
    end
  end
end
