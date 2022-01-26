require "rails_helper"

RSpec.describe Reports::MonthlyProgressComponent, type: :component do
  let(:facility) { create(:facility) }
  let(:user) { create(:user) }
  let(:query) { Reports::FacilityStateGroup.where(facility_region_id: facility.region.id) }
  let(:current_period) { Period.month("December 2021") }
  let(:range) { Range.new(current_period.advance(months: -5), current_period) }
  let(:results) { Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: @range).to_a }

  let(:jan_2022) { Time.zone.parse("January 1st, 2022 00:00:00+00:00") }

  it "returns totals based on metric / diagnosis" do
    patient_1 = create(:patient, :hypertension, recorded_at: 2.years.ago, registration_user: user, registration_facility: facility)
    refresh_views

    component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, results: results, range: range)
    expect(component.total_count).to eq(1)
  end

  it "returns the monthly count for a period and a gender" do
    Timecop.freeze("December 1st 2021 10:00:00 IST") do
      patient_1 = create(:patient, :hypertension, recorded_at: Time.current, registration_user: user, registration_facility: facility)
      refresh_views
    end
    Timecop.freeze(jan_2022) do
      component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, results: results, range: range)
      expect(component.total_count).to eq(1)
      expect(component.monthly_count(jan_2022)).to eq(1)
    end
  end

  it "returns valid diagnosis gender classes" do
    component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, results: results, range: range)
    expect(component.diagnosis_group_class("all")).to eq("all")
    expect(component.diagnosis_group_class("male")).to eq("male")
    expect(component.diagnosis_group_class("female")).to eq("female")

    component = described_class.new(facility: facility, diagnosis: :hypertension, metric: :registrations, results: results, range: range)
    expect(component.diagnosis_group_class("all")).to eq("hypertension:all")
    expect(component.diagnosis_group_class("male")).to eq("hypertension:male")
    expect(component.diagnosis_group_class("female")).to eq("hypertension:female")
  end
end
