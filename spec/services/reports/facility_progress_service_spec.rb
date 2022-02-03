require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  it "returns all dimension combinations" do
    facility = build(:facility)
    service = described_class.new(facility, Period.current)
    dimensions = service.dimension_combinations_for(:registrations)
    # (2 diagnosis options) * (4 gender options) + 1 special case of all / all
    expect(dimensions.size).to eq(9)
    expect(dimensions.all? { |d| d.indicator == :registrations }).to be true
    expect(dimensions.count { |d| d.diagnosis == :diabetes }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :hypertension }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :all }).to eq(1)
  end
end
