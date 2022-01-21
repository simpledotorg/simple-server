require "rails_helper"

describe Reports::SchemaV2, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  let(:range) { (july_2018..june_2020) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility) { create(:facility, name: "facility-1", facility_group: facility_group_1) }

  let(:jan_2019) { Time.zone.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.zone.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Period.month("July 1 2018") }
  let(:june_2020) { Period.month("June 1 2020") }

  def refresh_views
    RefreshReportingViews.new.refresh_v2
  end

  it "returns data correctly grouped when passed mixed region types" do
    facility_1, facility_2 = *FactoryBot.create_list(:facility, 2, block: "block-1", facility_group: facility_group_1).sort_by(&:slug)
    facility_3 = FactoryBot.create(:facility, block: "block-2", facility_group: facility_group_1)
    facilities = [facility_1, facility_2, facility_3]

    facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      (facility_1_controlled << facility_2_controlled).map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
      end
      facility_1_uncontrolled.map do |patient|
        create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago)
      end
    end

    refresh_views

    regions = [facility_group_1.region].concat(facilities.map(&:region))
    july_2021 = Period.month("July 1st 2021")
    range = (july_2021.advance(months: -24)..july_2021)
    result = described_class.new(regions, periods: range).send(:region_summaries)

    expect(result[facility_group_1.slug][jan_2020.to_period]).to include("cumulative_assigned_patients" => 5)
    expect(result[facility_group_1.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 3)
    expect(result[facility_1.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 2)
    expect(result[facility_2.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 1)
  end

  it "can return earliest patient recorded at" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility, registration_user: user) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    expect(schema.earliest_patient_recorded_at["facility-1"]).to eq(jan_2020)
  end

  it "has cache key" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility, registration_user: user) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    entries = schema.cache_entries(:earliest_patient_recorded_at)
    entries.each do |entry|
      expect(entry.to_s).to include("schema_v2")
      expect(entry.to_s).to include(facility.region.id)
      expect(entry.to_s).to include(schema.cache_version)
    end
  end

  describe "appointment scheduled days percentages" do
    it "returns percentages of appointments scheduled across months in a given range" do
      facility = create(:facility)
      create(:patient, assigned_facility: facility)
      range = Period.month(2.month.ago)..Period.current
      _appointment_scheduled_0_to_14_days = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.first]).to eq(0)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.to_a.second]).to eq(0)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(100)
    end

    it "returns percentages of appointments scheduled in a month in the given range" do
      facility = create(:facility)
      create(:patient, assigned_facility: facility)
      range = Period.month(2.month.ago)..Period.current
      _appointment_scheduled_0_to_14_days = create(:appointment, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
      _appointment_scheduled_15_to_30_days = create(:appointment, facility: facility, scheduled_date: 16.days.from_now, device_created_at: Date.today)
      _appointment_scheduled_31_to_60_days = create(:appointment, facility: facility, scheduled_date: 36.days.from_now, device_created_at: Date.today)
      _appointment_scheduled_more_than_60_days = create(:appointment, facility: facility, scheduled_date: 70.days.from_now, device_created_at: Date.today)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(25)
      expect(schema.appts_scheduled_15_to_30_days_rates[facility.slug][range.last]).to eq(25)
      expect(schema.appts_scheduled_31_to_60_days_rates[facility.slug][range.last]).to eq(25)
      expect(schema.appts_scheduled_more_than_60_days_rates[facility.slug][range.last]).to eq(25)
    end
  end
end
