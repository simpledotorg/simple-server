require "rails_helper"

RSpec.describe Reports::RegionSummary, {type: :model, reporting_spec: true} do
  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }

  def refresh_views
    RefreshReportingViews.new.refresh_v2
  end

  fit "works" do
    facility_1, facility_2 = *FactoryBot.create_list(:facility, 2, block: "block-1", facility_group: facility_group_1).sort_by(&:slug)
    facility_3 = FactoryBot.create(:facility, block: "block-2", facility_group: facility_group_1)
    facilities = [facility_1, facility_2, facility_3]
    district_region = facility_group_1.region
    block_regions = facilities.map(&:block_region)

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

    result = described_class.call(facilities, range: jan_2020)
    expect(result[facility_1.slug]).to eq(jan_2020.to_period => 2)

    jan_2020_data = described_class.where(month_date: jan_2020)
    expect(jan_2020_data.for_region(facility_1.region).to_a.first.adjusted_controlled_under_care).to eq(2)
    expect(jan_2020_data.for_region(facility_2.region).to_a.first.adjusted_controlled_under_care).to eq(1)
    expect(jan_2020_data.for_region(facility_3.region).to_a.first.adjusted_controlled_under_care).to be_nil

    district_data = jan_2020_data.for_region(district_region).summary(:district).to_a.first
    expect(district_data.adjusted_controlled_under_care).to eq(3)

    block_data = jan_2020_data.for_regions(block_regions).summary(:block)
    grouped_data = block_data.group_by { |r| r.block_region_id }
    expect(grouped_data[facility_1.block_region.id].first.adjusted_controlled_under_care).to eq(3)
    expect(grouped_data[facility_3.block_region.id].first.adjusted_controlled_under_care).to be_nil


  end
end