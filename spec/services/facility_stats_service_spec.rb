require "rails_helper"

RSpec.describe FacilityStatsService do
  let(:small_facility1) { create(:facility, name: "small1", facility_size: "small") }
  let(:small_facility2) { create(:facility, name: "small2", facility_size: "small") }
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

  def stats_of_type(stats, type)
    stats.map { |_, v| v[type] }
  end

  describe "#call" do
    it "sets default values for facilities_data and stats_by_size when no facilities are provided" do
      subject = FacilityStatsService.new(accessible_facilities: [], retain_facilities: [],
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call
      expect(subject.facilities_data).to eq({})
      expect(subject.stats_by_size).to eq({})
    end

    it "sets data for the past six periods" do
      facilities = [small_facility1]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call
      small = subject.stats_by_size["small"]
      periods = (1..5).inject([period]) { |periods, number|
        periods << periods.last.previous
      }
      expect(small.keys).to match_array(periods)
    end

    it "sets facilities data for all provided facilities" do
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call
      expect(subject.facilities_data.keys).to match_array([small_facility1.name, small_facility2.name])
      expect(subject.facilities_data.values.map(&:class).uniq).to eq([Reports::Result])
    end

    it "accurately tallies stats for facilities by size and period" do
      small_facilities = setup_for_size("small", december - 5.months)
      medium_facilities = setup_for_size("medium", december - 4.months)
      large_facilities = setup_for_size("large", december - 3.months)
      refresh_views
      all_facilities = small_facilities + medium_facilities + large_facilities
      subject = FacilityStatsService.new(accessible_facilities: all_facilities, retain_facilities: all_facilities,
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call

      # all numbers except cumulative_registrations appear in data 3 months after they're recorded
      small_controlled = [0, 0, 0, 2, 0, 0]
      small_adjusted = [0, 0, 0, 3, 3, 3]
      small_cumulative = [3, 3, 3, 3, 3, 3]
      small_rate = [0, 0, 0, 67, 0, 0]
      expect(stats_of_type(subject.stats_by_size["small"], "controlled_patients")).to eq small_controlled
      expect(stats_of_type(subject.stats_by_size["small"], "adjusted_registrations")).to eq small_adjusted
      expect(stats_of_type(subject.stats_by_size["small"], "cumulative_registrations")).to eq small_cumulative
      expect(stats_of_type(subject.stats_by_size["small"], "controlled_patients_rate")).to eq small_rate

      medium_controlled = [0, 0, 0, 0, 2, 0]
      medium_adjusted = [0, 0, 0, 0, 3, 3]
      medium_cumulative = [0, 3, 3, 3, 3, 3]
      medium_rate = [0, 0, 0, 0, 67, 0]
      expect(stats_of_type(subject.stats_by_size["medium"], "controlled_patients")).to eq medium_controlled
      expect(stats_of_type(subject.stats_by_size["medium"], "adjusted_registrations")).to eq medium_adjusted
      expect(stats_of_type(subject.stats_by_size["medium"], "cumulative_registrations")).to eq medium_cumulative
      expect(stats_of_type(subject.stats_by_size["medium"], "controlled_patients_rate")).to eq medium_rate

      large_controlled = [0, 0, 0, 0, 0, 2]
      large_adjusted = [0, 0, 0, 0, 0, 3]
      large_cumulative = [0, 0, 3, 3, 3, 3]
      large_rate = [0, 0, 0, 0, 0, 67]
      expect(stats_of_type(subject.stats_by_size["large"], "controlled_patients")).to eq large_controlled
      expect(stats_of_type(subject.stats_by_size["large"], "adjusted_registrations")).to eq large_adjusted
      expect(stats_of_type(subject.stats_by_size["large"], "cumulative_registrations")).to eq large_cumulative
      expect(stats_of_type(subject.stats_by_size["large"], "controlled_patients_rate")).to eq large_rate
    end

    it "sets stats for all accessible facilities but only sets facilities data for retained facilities" do
      small_facilities = setup_for_size("small")
      large_facilities = setup_for_size("large")
      accessible_facilities = small_facilities + large_facilities
      subject = FacilityStatsService.new(accessible_facilities: accessible_facilities, retain_facilities: large_facilities,
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call
      expect(subject.stats_by_size.keys).to match_array(["small", "large"])
      expect(subject.facilities_data.keys).to match_array(large_facilities.map(&:name))
    end

    it "processes data for controlled_patients" do
      facilities = setup_for_size("small")
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "controlled_patients")
      subject.call
      period_keys = subject.stats_by_size["small"].values.map(&:keys).flatten.uniq
      controlled_patient_keys = ["controlled_patients", "controlled_patients_rate"]
      expect(period_keys & controlled_patient_keys).to match_array(controlled_patient_keys)
    end

    it "processes data for missed_visits" do
      facilities = setup_for_size("small")
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "uncontrolled_patients")
      subject.call
      period_keys = subject.stats_by_size["small"].values.map(&:keys).flatten.uniq
      uncontrolled_patient_keys = ["uncontrolled_patients", "uncontrolled_patients_rate"]
      expect(period_keys & uncontrolled_patient_keys).to match_array(uncontrolled_patient_keys)
    end

    it "processes data for missed_visits" do
      facilities = setup_for_size("small")
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "missed_visits")
      subject.call
      period_keys = subject.stats_by_size["small"].values.map(&:keys).flatten.uniq
      missed_visits_keys = ["missed_visits", "missed_visits_rate"]
      expect(period_keys & missed_visits_keys).to match_array(missed_visits_keys)
    end

    it "handles invalid rate_numerator by setting values to zero" do
      facilities = setup_for_size("small")
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: "womp")
      subject.call
      stat_keys = subject.stats_by_size["small"].values.first.keys
      stat_values = subject.stats_by_size["small"].values.first.values
      expected_keys = ["womp", "adjusted_registrations", "cumulative_registrations", "womp_rate"]
      expect(stat_keys).to match_array(expected_keys)
      expect(stat_values).to match_array([0, 0, 0, 0])
    end
  end
end
