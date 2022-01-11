require "rails_helper"

RSpec.describe Reports::MonthlyProgressComponent, type: :component do
  let(:facility) { create(:facility) }
  let(:query) { Reports::FacilityStateGroup.where(facility_region_id: facility.region.id) }
  let(:current_period) { Period.month("December 2021") }
  let(:range) { Range.new(current_period.advance(months: -5), current_period) }

  it "returns valid diagnosis gender classes" do
    component = described_class.new(facility: facility, diagnosis: :all, metric: :registrations, query: query, range: range)
    expect(component.diagnosis_group_class("all")).to eq("all")
    expect(component.diagnosis_group_class("male")).to eq("male")
    expect(component.diagnosis_group_class("female")).to eq("female")

    component = described_class.new(facility: facility, diagnosis: :hypertension, metric: :registrations, query: query, range: range)
    expect(component.diagnosis_group_class("all")).to eq("hypertension:all")
    expect(component.diagnosis_group_class("male")).to eq("hypertension:male")
    expect(component.diagnosis_group_class("female")).to eq("hypertension:female")
  end

end
