require "rails_helper"

RSpec.describe ControlRateService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "returns registrations and control rates for a block" do
    brooklyn_facilities = FactoryBot.create_list(:facility, 2, block: "Brooklyn", facility_group: facility_group_1)
    queens_facility = FactoryBot.create(:facility, block: "Queens", facility_group: facility_group_1)
    facility_1, facility_2 = brooklyn_facilities[0], brooklyn_facilities[1]

    controlled_in_facility_1 = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019,
                                                        registration_facility: facility_1, registration_user: user)
    uncontrolled_in_facility_1 = create_list(:patient, 4, full_name: "uncontrolled", recorded_at: jan_2019,
                                                          registration_facility: facility_1, registration_user: user)
    controlled_in_facility_2 = create_list(:patient, 2, full_name: "other facility", recorded_at: jan_2019,
                                                        registration_facility: facility_2, registration_user: user)
    patient_from_other_block = create(:patient, full_name: "other block", recorded_at: jan_2019,
                                                registration_facility: queens_facility, registration_user: user)

    # sanity checks for proper amount of regions
    expect(Region.state_regions.count).to eq(1)
    expect(Region.count).to eq(9) # 1 root, 1 org, 1 state, 1 district, 2 blocks, 3 facilities

    Timecop.freeze(jan_2020) do
      (controlled_in_facility_1 + controlled_in_facility_2).map do |patient|
        create(:blood_pressure, :under_control, facility: patient.registration_facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: patient.registration_facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled_in_facility_1.map do |patient|
        create(:blood_pressure, :hypertensive, facility: patient.registration_facility,
                                               patient: patient, recorded_at: 4.days.ago, user: user)
      end
      create(:blood_pressure, :under_control, facility: queens_facility, patient: patient_from_other_block,
                                              recorded_at: 2.days.ago, user: user)
    end

    refresh_views

    periods = Period.month(july_2018)..Period.month(july_2020)
    service = ControlRateService.new(facility_1.block_region, periods: periods)
    result = service.call

    expect(result[:registrations][Period.month(jan_2019)]).to eq(8)
    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(4)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(50)
  end

  context "caching" do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
    let(:cache) { Rails.cache }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    it "has a cache key that distinguishes based on period" do
      region = facility_group_1.region

      month_periods = Period.month("September 1 2018")..Period.month("September 1 2020")
      earlier_month_periods = Period.month("January 1 2018")..Period.month("January 1 2020")
      quarter_periods = Period.quarter(july_2018)..Period.quarter(july_2020)
      Timecop.freeze("October 1 2020") do
        service_1 = ControlRateService.new(facility_group_1, periods: month_periods)
        expect(service_1.send(:cache_key)).to match(/regions\/district\/#{region.id}\/month/)

        service_2 = ControlRateService.new(facility_group_1, periods: earlier_month_periods)
        expect(service_2.send(:cache_key)).to match(/regions\/district\/#{region.id}\/month/)

        service_3 = ControlRateService.new(facility_group_1, periods: quarter_periods)
        expect(service_3.send(:cache_key)).to match(/regions\/district\/#{region.id}\/quarter/)
      end
    end
  end
end
