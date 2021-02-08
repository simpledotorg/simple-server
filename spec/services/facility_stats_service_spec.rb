require "rails_helper"

RSpec.describe FacilityStatsService do
  let(:small_facility) { create(:facility, name: "small1", facility_size: "small") }
  let(:december) { Date.parse("1-12-2020").beginning_of_month }
  let(:period) { Period.month(december) }

  def setup_for_size(size, month = december)
    Timecop.freeze(month) do
      facility1 = create(:facility, name: "#{size}_1", facility_size: size)
      facility2 = create(:facility, name: "#{size}_2", facility_size: size)
      controlled = create_list(:patient, 2, full_name: "#{size}_controlled", assigned_facility: facility1)
      uncontrolled = create_list(:patient, 1, full_name: "#{size}_uncontrolled", assigned_facility: facility2)
      # recorded_at needs to be in a month after registration in order to appear in control rate data
      controlled.each do |patient|
        create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility, recorded_at: month + 1.month)
      end
      uncontrolled.each do |patient|
        create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility, recorded_at: month + 1.month)
      end
      [facility1, facility2]
    end
  end

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  def facilities_data(facilities)
    facilities.each_with_object({}) do |facility, hsh|
      hsh[facility.name] = Reports::RegionService.new(region: facility, period: period).call
    end
  end

  describe "self.call" do
    it "sets default values for facilities_data and stats_by_size when no facilities are provided" do
      stats_by_size = FacilityStatsService.call(facilities: {}, ending_period: period,
                                                rate_numerator: "controlled_patients")
      expect(stats_by_size).to eq({})
    end

    it "sets data for the past six periods" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]), ending_period: period,
                                                rate_numerator: "controlled_patients")
      small = stats_by_size["small"]
      periods = (1..5).inject([period]) { |periods, number|
        periods << periods.last.previous
      }
      expect(small.keys).to match_array(periods)
    end

    it "accurately tallies stats for facilities by size and period" do
      small_facilities = setup_for_size("small", december - 5.months)
      medium_facilities = setup_for_size("medium", december - 4.months)
      large_facilities = setup_for_size("large", december - 3.months)
      refresh_views
      all_facilities = small_facilities + medium_facilities + large_facilities
      stats_by_size = FacilityStatsService.call(facilities: facilities_data(all_facilities),
                                                ending_period: period, rate_numerator: "controlled_patients")

      # all numbers except cumulative_registrations appear in data 3 months after they're recorded
      small = stats_by_size["small"]
      expect(small.map { |_, v| v["controlled_patients"] }).to eq [0, 0, 0, 2, 0, 0]
      expect(small.map { |_, v| v["adjusted_registrations"] }).to eq [0, 0, 0, 3, 3, 3]
      expect(small.map { |_, v| v["cumulative_registrations"] }).to eq [3, 3, 3, 3, 3, 3]
      expect(small.map { |_, v| v["controlled_patients_rate"] }).to eq [0, 0, 0, 67, 0, 0]

      medium = stats_by_size["medium"]
      expect(medium.map { |_, v| v["controlled_patients"] }).to eq [0, 0, 0, 0, 2, 0]
      expect(medium.map { |_, v| v["adjusted_registrations"] }).to eq [0, 0, 0, 0, 3, 3]
      expect(medium.map { |_, v| v["cumulative_registrations"] }).to eq [0, 3, 3, 3, 3, 3]
      expect(medium.map { |_, v| v["controlled_patients_rate"] }).to eq [0, 0, 0, 0, 67, 0]

      large = stats_by_size["large"]
      expect(large.map { |_, v| v["controlled_patients"] }).to eq [0, 0, 0, 0, 0, 2]
      expect(large.map { |_, v| v["adjusted_registrations"] }).to eq [0, 0, 0, 0, 0, 3]
      expect(large.map { |_, v| v["cumulative_registrations"] }).to eq [0, 0, 3, 3, 3, 3]
      expect(large.map { |_, v| v["controlled_patients_rate"] }).to eq [0, 0, 0, 0, 0, 67]
    end

    it "processes data for controlled_patients" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                ending_period: period, rate_numerator: "controlled_patients")
      period_keys = stats_by_size["small"].values.map(&:keys).flatten.uniq
      controlled_patient_keys = ["controlled_patients", "controlled_patients_rate"]
      expect(period_keys & controlled_patient_keys).to match_array(controlled_patient_keys)
    end

    it "processes data for missed_visits" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                ending_period: period, rate_numerator: "uncontrolled_patients")
      period_keys = stats_by_size["small"].values.map(&:keys).flatten.uniq
      uncontrolled_patient_keys = ["uncontrolled_patients", "uncontrolled_patients_rate"]
      expect(period_keys & uncontrolled_patient_keys).to match_array(uncontrolled_patient_keys)
    end

    it "processes data for missed_visits" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                ending_period: period, rate_numerator: "missed_visits")
      period_keys = stats_by_size["small"].values.map(&:keys).flatten.uniq
      missed_visits_keys = ["missed_visits", "missed_visits_rate"]
      expect(period_keys & missed_visits_keys).to match_array(missed_visits_keys)
    end

    it "handles invalid rate_numerator by setting values to zero" do
      stats_by_size = FacilityStatsService.call(facilities: facilities_data([small_facility]),
                                                ending_period: period, rate_numerator: "womp")
      stat_keys = stats_by_size["small"].values.first.keys
      stat_values = stats_by_size["small"].values.first.values
      expected_keys = ["womp", "adjusted_registrations", "cumulative_registrations", "womp_rate"]
      expect(stat_keys).to match_array(expected_keys)
      expect(stat_values).to match_array([0, 0, 0, 0])
    end
  end
end
