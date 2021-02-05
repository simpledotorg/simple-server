require 'rails_helper'

RSpec.describe FacilityStatsService do
  let(:december) { Date.parse('1-12-2020').beginning_of_month }
  let(:september) { 'September 20th 2020' }
  let(:august) { 'August 15th 2020' }
  let(:july) { 'July 25th 2020' }

  let(:organization) { create(:organization, name: "org-1") }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:small_facility1) { create(:facility, name: 'small1', facility_size: 'small', facility_group: facility_group) }
  let(:small_facility2) { create(:facility, name: 'small2', facility_size: 'small', facility_group: facility_group) }
  let(:medium_facility1) { create(:facility, name: 'medium1', facility_size: 'medium', facility_group: facility_group) }
  let(:medium_facility2) { create(:facility, name: 'medium2', facility_size: 'medium', facility_group: facility_group) }
  let(:large_facility1) { create(:facility, name: 'large1', facility_size: 'large', facility_group: facility_group) }
  let(:large_facility2) { create(:facility, name: 'large2', facility_size: 'large', facility_group: facility_group) }
  let(:all_facilities) { [small_facility1, small_facility2, medium_facility1, medium_facility2, large_facility1, large_facility2] }
  let(:period) { Period.month(december) }

  # def facility_only_setup
  #   Timecop.freeze(september) do
  #     small_controlled = create_list(:patient, 2, full_name: 'small_controlled', assigned_facility: small_facility1)
  #     small_uncontrolled = create_list(:patient, 1, full_name: 'small_uncontrolled', assigned_facility: small_facility2)
  #     small_controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility) }
  #     small_uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility) }
  #   end
  # end

  def small_data_setup
    Timecop.freeze(september) do
      small_controlled = create_list(:patient, 2, full_name: 'small_controlled', assigned_facility: small_facility1)
      small_uncontrolled = create_list(:patient, 1, full_name: 'small_uncontrolled', assigned_facility: small_facility2)
      small_controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility) }
      small_uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility) }
    end
  end

  def all_sizes_data_setup
    small_controlled = nil
    small_uncontrolled = nil
    medium_controlled = nil
    medium_uncontrolled = nil
    large_controlled = nil
    large_uncontrolled = nil
    Timecop.freeze(six_months_ago) do
      large_controlled = create_list(:patient, 3, full_name: 'large_controlled', assigned_facility: large_facility1)
    end
    Timecop.freeze(five_months_ago) do
      small_controlled = create_list(:patient, 2, full_name: 'small_controlled', assigned_facility: small_facility1, registration_user: supervisor)
      small_uncontrolled = create_list(:patient, 1, full_name: 'small_uncontrolled', assigned_facility: small_facility2, registration_user: supervisor)
      medium_uncontrolled = create_list(:patient, 2, full_name: 'medium_uncontrolled', assigned_facility: medium_facility1)
      large_uncontrolled = create_list(:patient, 1, full_name: 'large_uncontrolled', assigned_facility: large_facility2)

      medium_uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility) }
      large_controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility) }
    end
    Timecop.freeze(four_months_ago) do
      medium_controlled = create_list(:patient, 2, full_name: 'medium_uncontrolled', assigned_facility: medium_facility1)

      medium_controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility) }
      small_controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: patient.assigned_facility, user: supervisor) }
      small_uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility, user: supervisor) }
      large_uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: patient.assigned_facility) }
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
      subject = FacilityStatsService.new(accessible_facilities: all_facilities, retain_facilities: all_facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
    end

    it 'does not include a size if no facilities of that size were queried' do
      # unclear if this is really what we want to do
    end

    it 'processes data for controlled_patients' do
      small_data_setup
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'controlled_patients')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      controlled_patient_keys = ['controlled_patients', 'controlled_patients_rate']
      expect(period_keys & controlled_patient_keys).to match_array(controlled_patient_keys)
    end

    it 'processes data for missed_visits' do
      small_data_setup
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'uncontrolled_patients')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      uncontrolled_patient_keys = ['uncontrolled_patients', 'uncontrolled_patients_rate']
      expect(period_keys & uncontrolled_patient_keys).to match_array(uncontrolled_patient_keys)
    end

    it 'processes data for missed_visits' do
      small_data_setup
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(accessible_facilities: facilities, retain_facilities: facilities,
                                         ending_period: period, rate_numerator: 'missed_visits')
      subject.call
      period_keys = subject.stats_by_size['small'].values.map(&:keys).flatten.uniq
      missed_visits_keys = ['missed_visits', 'missed_visits_rate']
      expect(period_keys & missed_visits_keys).to match_array(missed_visits_keys)
    end

    it 'raises error when given an invalid key' do

    end
  end
end