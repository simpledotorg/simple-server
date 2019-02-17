require 'rails_helper'

RSpec.feature 'Facility Group Analytics', type: :feature do
  let(:facility_group) { create :facility_group }
  let(:owner) { create :admin, :owner }
  let(:facilities) { create_list :facility, 2, facility_group: facility_group }

  describe 'last 90 days tab' do
    let(:from_time) { 90.days.ago }
    let(:to_time) { Date.today }

    let!(:newly_enrolled_patients) do
      facilities.flat_map do |facility|
        create_list_in_period(:patient, 3, from_time: from_time, to_time: to_time, registration_facility: facility)
      end
    end

    let!(:non_returning_patients) do
      facilities.flat_map do |facility|
        create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
      end
    end

    let!(:non_returning_hypertensive_patients) do
      facilities.flat_map do |facility|
        patients = create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
        patients.each do |patient|
          create_in_period(
            :blood_pressure,
            trait: :hypertensive, from_time: patient.device_created_at, to_time: from_time,
            patient: patient, facility: facility)
        end
        patients
      end
    end

    let!(:returning_patients) do
      facilities.flat_map do |facility|
        patients = create_list_in_period(:patient, 2, from_time: Time.new(0), to_time: from_time, registration_facility: facility)
        patients.each do |patient|
          create_in_period(:blood_pressure, from_time: from_time, to_time: to_time, patient: patient, facility: facility)
        end
        patients
      end
    end

    let!(:hypertensive_patients_registered_9_months_ago) do
      facilities.flat_map do |facility|
        patients = create_list_in_period(:patient, 2, from_time: from_time - 9.months, to_time: to_time - 9.months, registration_facility: facility)
        patients.each do |patient|
          create_in_period(
            :blood_pressure,
            trait: :hypertensive, from_time: from_time - 9.months, to_time: to_time - 9.months,
            patient: patient, facility: facility)
        end
        patients
      end
    end

    let!(:patients_under_control_in_period) do
      patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(2)
      patients_under_control_in_period.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end
      patients_under_control_in_period
    end

    before :each do
      sign_in(owner)
      visit analytics_facility_group_path(facility_group)
    end

    it 'contains a link to the graphics page for facility group' do
      expect(page).to have_link(nil, href: analytics_facility_group_graphics_path(facility_group))
    end

    it 'contains the number of newly enrolled patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility_groups.newly_enrolled'))
      expect(page.find('#newly-enrolled-patients-count')).to have_content(newly_enrolled_patients.size)
    end

    it 'contains the number of returning patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility_groups.return_patients'))
      expect(page.find('#returning-patients-count')).to have_content(returning_patients.size)
    end

    it 'contains the number of non returning hypertensive patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility_groups.non_returning_hypertensive_patients'))
      expect(page.find('#non-returning-hypertensive-patients-count')).to have_content(non_returning_hypertensive_patients.size)
    end

    it 'contains a graph with number of non returning hypertensive patients per month' do
      expect(page).to have_css('#non-returning-hypertensive-patients-chart')
    end

    it 'contains the control rate for the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.graphics.facility_groups.control_rate'))
      expect(page.find('#non-returning-hypertensive-patients-count')).to have_content(50)
    end

    it 'contains links to analytics for all facilities in the facility group' do
      facilities.each do |facility|
        expect(page).to have_link(facility.name, href: analytics_facility_path(facility))
      end
    end
  end
end
