require 'rails_helper'

RSpec.describe FacilityStatsService do

  let(:small_facility1) { create(:facility, name: 'small1', facility_size: 'small') }
  let(:small_facility2) { create(:facility, name: 'small2', facility_size: 'small') }
  let(:december) { Date.parse('1-12-2020').beginning_of_month }
  let(:august) { 'August 15th 2020' }
  let(:period) { Period.month(december) }

  def setup_for_size(size)
    Timecop.freeze(august) do
      facility1 = create(:facility, name: "#{size}_1", facility_size: size)
      facility2 = create(:facility, name: "#{size}_2", facility_size: size)
      controlled = create_list(:patient, 2, full_name: "#{size}_controlled", assigned_facility: facility1)
      uncontrolled = create_list(:patient, 1, full_name: "#{size}_uncontrolled", assigned_facility: facility2)
      controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility, recorded_at: Date.today + 1.month) }
      uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility, recorded_at: Date.today + 1.month) }
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

  def stats_of_type(stats, size, type)
    months.map {|month| stats[size][month][type] }
  end

  describe '#call' do
    context 'with no facilities provided' do
      it 'sets default values for facilities_data and stats_by_size' do
        subject = FacilityStatsService.new(accessible_facilities: [], retain_facilities: [],
                                           ending_period: period, rate_numerator: 'controlled_patients')
        subject.call
        expect(subject.facilities_data).to eq({})
        expect(subject.stats_by_size).to eq({})
      end
    end

    it 'sets data for past six periods' do
      facilities = [small_facility1]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
      small = subject.stats_by_size['small']
      periods = (1..5).inject([period]) do |periods, number|
        periods << periods.last.previous
      end
      expect(small.keys).to match_array(periods)
    end

    it 'sets facilities data for all provided facilities' do
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
      expect(subject.facilities_data.keys).to match_array([small_facility1.name, small_facility2.name])
      expect(subject.facilities_data.values.map(&:class).uniq).to eq([Reports::Result])
    end

    it 'accurately tallies stats for facilities by size and period' do
      small_facilities = setup_for_size('small')
      medium_facilities = setup_for_size('medium')
      large_facilities = setup_for_size('large')
      refresh_views
      all_facilities = small_facilities + medium_facilities + large_facilities
      subject = FacilityStatsService.new(accessible_facilities: all_facilities, retain_facilities: all_facilities,
                                         ending_period: period, rate_numerator: 'uncontrolled_patients')
      subject.call
      
    end

    it 'sets stats for all accessible facilities but only sets facilities data for retained facilities' do
      small_facilities = setup_for_size('small')
      large_facilities = setup_for_size('large')
      accessible_facilities = small_facilities + large_facilities
      subject = FacilityStatsService.new(accessible_facilities: accessible_facilities, retain_facilities: large_facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
      expect(subject.stats_by_size.keys).to match_array(['small', 'large'])
      expect(subject.facilities_data.keys).to match_array(large_facilities.map(&:name))
    end

    it 'processes data for controlled_patients' do
      facilities = setup_for_size('small')
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      controlled_patient_keys = ['controlled_patients', 'controlled_patients_rate']
      expect(period_keys & controlled_patient_keys).to match_array(controlled_patient_keys)
    end

    it 'processes data for missed_visits' do
      facilities = setup_for_size('small')
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'uncontrolled_patients')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      uncontrolled_patient_keys = ['uncontrolled_patients', 'uncontrolled_patients_rate']
      expect(period_keys & uncontrolled_patient_keys).to match_array(uncontrolled_patient_keys)
    end

    it 'processes data for missed_visits' do
      facilities = setup_for_size('small')
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'missed_visits')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      missed_visits_keys = ['missed_visits', 'missed_visits_rate']
      expect(period_keys & missed_visits_keys).to match_array(missed_visits_keys)
    end

    it 'handles invalid rate_numerator by setting keys to zero' do
      facilities = setup_for_size('small')
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'womp')
      subject.call
      stat_keys = subject.stats_by_size['small'].values.first.keys
      stat_values = subject.stats_by_size['small'].values.first.values
      expected_keys = ['womp', 'adjusted_registrations', 'cumulative_registrations', 'womp_rate']
      expect(stat_keys).to match_array(expected_keys)
      expect(stat_values).to match_array([0, 0, 0, 0])
    end
  end
end