require "rails_helper"

RSpec.describe Reports::MonthlyProgressComponent, type: :component do
  using StringToPeriod

  let(:november_2021_period) { Period.month("November 1st 2021") }
  let(:december_2021_period) { Period.month("December 1st 2021") }
  let(:jan_2022) { Time.zone.parse("January 1st, 2022 00:00:00+00:00") }

  let(:facility) { create(:facility) }
  let(:user) { create(:user) }
  let(:range) { Range.new(Period.month("June 1st 2021"), Period.month("December 1st 2021")) }
  let(:date_range) { range.map(&:to_date) }
  let(:counts) { Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: date_range).to_a }
  let(:total_counts) { Reports::FacilityStateGroup.totals(facility) }

  it "returns totals based on metric / diagnosis" do
    create(:patient, :hypertension, recorded_at: 2.years.ago, registration_user: user, registration_facility: facility)
    refresh_views

    component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, counts: counts, total_counts: total_counts, range: range)
    expect(component.total_count).to eq(1)
  end

  it "returns the total and monthly counts for :all diagnosis" do
    Timecop.freeze("November 1st 2021 10:00:00 IST") do
      create(:patient, :hypertension, gender: :female, recorded_at: Time.current, registration_user: user, registration_facility: facility)
    end
    Timecop.freeze(jan_2022) do
      refresh_views
      counts = Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: date_range)

      component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, counts: counts, total_counts: total_counts, range: range)

      expect(component.total_count).to eq(1)
      expect(component.monthly_count(november_2021_period)).to eq(1)
    end
  end

  it "returns the monthly counts by gender for :hypertension" do
    Timecop.freeze("November 1st 2021 10:00:00 IST") do
      create(:patient, :hypertension, gender: :female, recorded_at: Time.current, registration_user: user, registration_facility: facility)
    end
    Timecop.freeze(jan_2022) do
      refresh_views
      counts = Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: date_range)

      component = described_class.new(facility: facility, diagnosis: :hypertension, metric: :registrations, counts: counts, total_counts: total_counts, range: range)
      expect(component.monthly_count_by_gender(november_2021_period, :female)).to eq(1)
      expect(component.monthly_count_by_gender(november_2021_period, :male)).to eq(0)

      expect(component.monthly_count_by_gender(december_2021_period, :female)).to be_nil
      expect(component.monthly_count_by_gender(december_2021_period, :male)).to be_nil
    end
  end

  it "returns valid diagnosis gender classes" do
    component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, counts: counts, total_counts: total_counts, range: range)
    expect(component.diagnosis_group_class("all")).to eq("all")
    expect(component.diagnosis_group_class("male")).to eq("male")
    expect(component.diagnosis_group_class("female")).to eq("female")

    component = described_class.new(facility: facility, diagnosis: :hypertension, metric: :registrations, counts: counts, total_counts: total_counts, range: range)
    expect(component.diagnosis_group_class("all")).to eq("hypertension:all")
    expect(component.diagnosis_group_class("male")).to eq("hypertension:male")
    expect(component.diagnosis_group_class("female")).to eq("hypertension:female")
  end
end
