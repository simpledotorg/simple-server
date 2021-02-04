require 'rails_helper'

RSpec.describe FacilityStatsService do
  let(:today) {'January 15th 2021' }
  let(:four_months_ago) { 'September 20th 2020' }
  let(:five_months_ago) { 'August 15th 2020' }
  let(:six_months_ago) { 'July 25th 2020' }

  let(:organization) { create(:organization, name: "org-1") }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let!(:small_facility1) { create(:facility, name: 'small1', facility_size: 'small', facility_group: facility_group) }
  let!(:small_facility2) { create(:facility, name: 'small2', facility_size: 'small', facility_group: facility_group) }
  let!(:medium_facility1) { create(:facility, name: 'medium1', facility_size: 'medium', facility_group: facility_group) }
  let!(:medium_facility2) { create(:facility, name: 'medium2', facility_size: 'medium', facility_group: facility_group) }
  let!(:large_facility1) { create(:facility, name: 'large1', facility_size: 'large', facility_group: facility_group) }
  let!(:large_facility2) { create(:facility, name: 'large2', facility_size: 'large', facility_group: facility_group) }
  let(:all_facilities) { [small_facility1, small_facility2, medium_facility1, medium_facility2, large_facility1, large_facility2] }
  let(:period) { Period.month(today) }

  # this is intended to create a semi-randomized assortment of data that covers most cases
  before :each do
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
    refresh_views
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
        subject = FacilityStatsService.new([], period, 'controlled_patients')
        subject.call
        expect(subject.facilities_data).to eq({})
        expect(subject.stats_by_size).to eq({})
      end
    end

    it 'sets data for this month and five months prior' do
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(facilities, period, 'controlled_patients')
      subject.call
      small = subject.stats_by_size['small']
      periods = (1..5).inject([period]) do |periods, number|
        periods << periods.last.previous
      end
      expect(small.keys).to match_array(periods)
    end

    it 'sets facilities data for all provided facilities' do
      facilities = [small_facility1, small_facility2]
      subject = FacilityStatsService.new(facilities, period, 'controlled_patients')
      subject.call
      expect(subject.facilities_data.keys).to match_array([small_facility1.name, small_facility2.name])
      expect(subject.facilities_data.values.map(&:class).uniq).to eq([Reports::Result])
    end

    it 'accurately tallies stats for facilities by size and period' do
      refresh_views
      subject = FacilityStatsService.new(all_facilities, period, 'controlled_patients')
      subject.call
    end

    it 'does not include a size if no facilities of that size were queried' do

    end

    it 'processes data for controlled_patients' do
    end

    it 'processes data for uncontrolled_patients' do
    end

    it 'processes data for missed_visits' do
    end

    it 'handles invalid numerators' do

    end
  end
end