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
  let(:counts) { Reports::FacilityStateDimension.where(facility_region_id: facility.region.id, month_date: date_range).to_a }
  let(:total_counts) { Reports::FacilityStateDimension.totals(facility) }
  let(:service) { Reports::FacilityProgressService.new(facility, december_2021_period) }

  it "returns totals based the dimension" do
    create(:patient, :hypertension, recorded_at: 2.years.ago, gender: :male, registration_user: user, registration_facility: facility)
    create(:patient, :hypertension, recorded_at: 2.years.ago, gender: :female, registration_user: user, registration_facility: facility)
    refresh_views

    dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :all, gender: :all)
    component = described_class.new(dimension, service: service)
    expect(component.total_count).to eq(2)
    dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :hypertension, gender: :female)
    component = described_class.new(dimension, service: service)
    expect(component.total_count).to eq(1)
  end

  it "returns the total and monthly counts for :all diagnosis" do
    Timecop.freeze("November 1st 2021 10:00:00 IST") do
      create(:patient, :hypertension, gender: :female, recorded_at: Time.current, registration_user: user, registration_facility: facility)
    end
    Timecop.freeze(jan_2022) do
      refresh_views
      dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :all, gender: :all)
      component = described_class.new(dimension, service: service)

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
      male = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :hypertension, gender: :male)
      male_component = described_class.new(male, service: service)
      expect(male_component.monthly_count(november_2021_period)).to eq(0)
      expect(male_component.monthly_count(december_2021_period)).to be_nil

      female = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :hypertension, gender: :female)
      female_component = described_class.new(female, service: service)
      expect(female_component.monthly_count(november_2021_period)).to eq(1)
      expect(female_component.monthly_count(december_2021_period)).to be_nil
    end
  end

  it "returns valid diagnosis gender classes" do
    dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :hypertension, gender: :male)
    component = described_class.new(dimension, service: service)
    expect(component.diagnosis_group_class).to eq("hypertension:male")

    dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :diabetes, gender: :all)
    component = described_class.new(dimension, service: service)
    expect(component.diagnosis_group_class).to eq("diabetes:all")
  end
end
