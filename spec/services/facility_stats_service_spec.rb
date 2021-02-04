require "rails_helper"

# should this be model?
RSpec.describe FacilityStatsService, type: :model do
  # let(:facility_group) { create(:facility_group) }
  let!(:small_facility1) { create(:facility, name: 'small1', facility_size: 'small') }
  let!(:small_facility2) { create(:facility, name: 'small2', facility_size: 'small') }
  let!(:medium_facility1) { create(:facility, name: 'medium1', facility_size: 'medium') }
  let!(:medium_facility2) { create(:facility, name: 'medium2', facility_size: 'medium') }
  let!(:large_facility1) { create(:facility, name: 'large1', facility_size: 'large') }
  let!(:large_facility2) { create(:facility, name: 'large2', facility_size: 'large') }
  let!(:period) { Period.month(Date.today) }

  # before :each do
  #   controlled = nil
  #   uncontrolled = nil
  #   Timecop.freeze("August 15th 2020") do
  #     controlled = create_list(:patient, 2, full_name: "controlled", assigned_facility: small_facility1, registration_user: supervisor)
  #     uncontrolled = create_list(:patient, 1, full_name: "uncontrolled", assigned_facility: small_facility2, registration_user: supervisor)
  #   end
  #   Timecop.freeze("September 20th 2020") do
  #     controlled.each { |patient| create(:blood_pressure, :under_control, patient: patient, facility: facility, user: supervisor) }
  #     uncontrolled.each { |patient| create(:blood_pressure, :hypertensive, patient: patient, facility: facility, user: supervisor) }
  #   end
  # end

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

    # this should probably also test the facilities data
    # once i have data set up
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