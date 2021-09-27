require "rails_helper"

RSpec.describe FacilityStatsService do
  let(:organization) { Seed.seed_org }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:small_facility) { create(:facility, name: "small1", facility_group: facility_group, facility_size: "small") }
  let(:december) { Date.parse("12-01-2020").beginning_of_month }
  let(:period) { Period.month(december) }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  def refresh_views
    LatestBloodPressuresPerPatientPerMonth.refresh
    LatestBloodPressuresPerPatientPerQuarter.refresh
    PatientRegistrationsPerDayPerFacility.refresh
  end

  def facilities_data(facilities)
    facilities.each_with_object({}) do |facility, hsh|
      hsh[facility.name] = Reports::RegionService.new(region: facility, period: period).call
    end
  end

  describe "self.call" do
    it "sets default values for facilities_data and stats_by_size when no facilities are provided" do
      expect(small_facility.organization).to eq(organization)
      stats_by_size = FacilityStatsService.call(facilities: {}, period: period,
                                                rate_numerator: :controlled_patients)
      expect(stats_by_size).to eq({})
    end

    it "sets data for the past six periods" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]), period: period,
                                                rate_numerator: :controlled_patients)
      small = stats_by_size[:small][:periods]
      periods = (1..5).inject([period]) { |periods|
        periods << periods.last.previous
      }
      expect(small.keys).to match_array(periods)
    end

    it "accurately tallies stats for facilities by size and period" do
      small_facility1 = create(:facility, name: "small_1", facility_group: facility_group, facility_size: "small")
      small_facility2 = create(:facility, name: "small_2", facility_group: facility_group, facility_size: "small")
      small_controlled = create_list(:patient, 2, full_name: "small_controlled", registration_user: user,
                                                  registration_facility: small_facility1, recorded_at: december - 5.months)
      small_uncontrolled = create(:patient, full_name: "small_uncontrolled", registration_facility: small_facility2,
                                            recorded_at: december - 5.months, registration_user: user)
      # recorded_at needs to be in a month after registration in order to appear in control rate data
      small_controlled.each do |patient|
        logger.info "--- start"
        create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility,
                                                recorded_at: december - 4.months, user: user)
        logger.info "--- end"
      end
      create(:blood_pressure, :hypertensive, patient: small_uncontrolled, facility: small_uncontrolled.assigned_facility,
                                             recorded_at: december - 4.months, user: user)

      medium_facility1 = create(:facility, name: "medium_1", facility_size: "medium", facility_group: facility_group)
      medium_facility2 = create(:facility, name: "medium_2", facility_size: "medium", facility_group: facility_group)
      medium_controlled = create(:patient, full_name: "medium_controlled", registration_facility: medium_facility1,
                                           recorded_at: december - 4.months, registration_user: user)
      medium_uncontrolled = create(:patient, full_name: "medium_uncontrolled", registration_facility: medium_facility2,
                                             recorded_at: december - 4.months, registration_user: user)
      create(:blood_pressure, :under_control, patient: medium_controlled, user: user,
                                              facility: medium_controlled.assigned_facility, recorded_at: december - 3.months)
      create(:blood_pressure, :hypertensive, patient: medium_uncontrolled, user: user,
                                             facility: medium_controlled.assigned_facility, recorded_at: december - 3.months)

      large_facility1 = create(:facility, name: "large_1", facility_size: "large", facility_group: facility_group)
      large_facility2 = create(:facility, name: "large_2", facility_size: "large", facility_group: facility_group)
      large_controlled = create(:patient, full_name: "large_controlled", registration_user: user,
                                          registration_facility: large_facility1, recorded_at: december - 3.months)
      expect(large_controlled.registration_facility).to eq(large_controlled.assigned_facility)
      large_uncontrolled = create_list(:patient, 2, full_name: "large_uncontrolled", registration_user: user,
                                                    registration_facility: large_facility2, recorded_at: december - 3.months)
      create(:blood_pressure, :under_control, patient: large_controlled, user: user,
                                              facility: large_controlled.assigned_facility, recorded_at: december - 2.months)
      large_uncontrolled.each do |patient|
        create(:blood_pressure, :hypertensive, patient: patient, user: user,
                                               facility: patient.assigned_facility, recorded_at: december - 2.months)
      end

      all_facilities = [small_facility1, small_facility2, medium_facility1,
        medium_facility2, large_facility1, large_facility2]
      refresh_views

      stats_by_size = with_reporting_time_zone {
        FacilityStatsService.call(facilities: facilities_data(all_facilities), period: period, rate_numerator: :controlled_patients)
      }

      # all numbers except cumulative_registrations appear in data 3 months after they're recorded
      small = stats_by_size[:small][:periods]
      expect(small.map { |_, v| v[:controlled_patients] }).to eq [0, 0, 0, 2, 0, 0]
      expect(small.map { |_, v| v[:adjusted_patient_counts] }).to eq [0, 0, 0, 3, 3, 3]
      expect(small.map { |_, v| v[:cumulative_registrations] }).to eq [3, 3, 3, 3, 3, 3]
      expect(small.map { |_, v| v[:cumulative_assigned_patients] }).to eq [3, 3, 3, 3, 3, 3]
      expect(small.map { |_, v| v[:controlled_patients_rate] }).to eq [0, 0, 0, 67, 0, 0]

      medium = stats_by_size[:medium][:periods]
      expect(medium.map { |_, v| v[:controlled_patients] }).to eq [0, 0, 0, 0, 1, 0]
      expect(medium.map { |_, v| v[:adjusted_patient_counts] }).to eq [0, 0, 0, 0, 2, 2]
      expect(medium.map { |_, v| v[:cumulative_registrations] }).to eq [0, 2, 2, 2, 2, 2]
      expect(medium.map { |_, v| v[:cumulative_assigned_patients] }).to eq [0, 2, 2, 2, 2, 2]
      expect(medium.map { |_, v| v[:controlled_patients_rate] }).to eq [0, 0, 0, 0, 50, 0]

      large = stats_by_size[:large][:periods]
      expect(large.map { |_, v| v[:controlled_patients] }).to eq [0, 0, 0, 0, 0, 1]
      expect(large.map { |_, v| v[:adjusted_patient_counts] }).to eq [0, 0, 0, 0, 0, 3]
      expect(large.map { |_, v| v[:cumulative_registrations] }).to eq [0, 0, 3, 3, 3, 3]
      expect(large.map { |_, v| v[:cumulative_assigned_patients] }).to eq [0, 0, 3, 3, 3, 3]
      expect(large.map { |_, v| v[:controlled_patients_rate] }).to eq [0, 0, 0, 0, 0, 33]
    end

    it "processes data for controlled_patients" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                period: period, rate_numerator: :controlled_patients)
      period_keys = stats_by_size[:small][:periods].values.map(&:keys).flatten.uniq
      controlled_patient_keys = ["controlled_patients", "controlled_patients_rate"]
      expect(period_keys & controlled_patient_keys).to match_array(controlled_patient_keys)
    end

    it "processes data for uncontrolled_patients" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                period: period, rate_numerator: :uncontrolled_patients)
      period_keys = stats_by_size[:small][:periods].values.map(&:keys).flatten.uniq
      uncontrolled_patient_keys = ["uncontrolled_patients", "uncontrolled_patients_rate"]
      expect(period_keys & uncontrolled_patient_keys).to match_array(uncontrolled_patient_keys)
    end

    it "processes data for missed_visits" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                period: period, rate_numerator: :missed_visits)
      period_keys = stats_by_size[:small][:periods].values.map(&:keys).flatten.uniq
      missed_visits_keys = ["missed_visits", "missed_visits_rate"]
      expect(period_keys & missed_visits_keys).to match_array(missed_visits_keys)
    end

    it "handles invalid rate_numerator by setting values to zero" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                period: period, rate_numerator: :womp)
      stat_keys = stats_by_size[:small][:periods].values.first.keys
      stat_values = stats_by_size[:small][:periods].values.first.values
      expected_keys = ["womp", "adjusted_patient_counts", "cumulative_registrations", "cumulative_assigned_patients", "womp_rate"]
      expect(stat_keys).to match_array(expected_keys)
      expect(stat_values).to match_array([0, 0, 0, 0, 0])
    end
  end
end
