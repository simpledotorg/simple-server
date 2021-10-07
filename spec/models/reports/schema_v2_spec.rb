require "rails_helper"

describe Reports::SchemaV2, type: :model do
  let(:july_2018) { Period.month("July 1 2018") }
  let(:june_2020) { Period.month("June 1 2020") }

  let(:jan_2020) { Time.zone.parse("January 1st, 2020 00:00:00+00:00") }
  let(:range) { (july_2018..june_2020) }
  let(:facility) { create(:facility) }

  def refresh_views
    RefreshReportingViews.new.refresh_v2
  end

  it "can return earliest patient recorded at" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    expect(schema.earliest_patient_recorded_at["facility-1"]).to eq(jan_2020)
  end

  it "has cache key" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    entries = schema.cache_entries(:earliest_patient_recorded_at)
    entries.each do |entry|
      expect(entry.to_s).to include("schema_v2")
      expect(entry.to_s).to include(facility.region.id)
      expect(entry.to_s).to include(schema.cache_version)
    end
  end
end
