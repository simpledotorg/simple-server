require 'rails_helper'

RSpec.feature 'Facility Analytics', type: :feature do
  let(:facility_group) { create :facility_group }
  let(:owner) { create :admin, :owner }
  let(:facility) { create :facility, facility_group: facility_group }
  let!(:users) { create_list :user, 5, facility: facility }

  describe 'last 90 days tab' do
    let(:from_time) { 90.days.ago }
    let(:to_time) { Date.today }

    let!(:newly_enrolled_patients) do
      create_list_in_period(
        :patient, 5,
        from_time: from_time, to_time: to_time,
        registration_facility: facility)
    end

    let!(:non_returning_patients) do
      create_list_in_period(
        :patient, 2,
        from_time: 1.year.ago, to_time: from_time,
        registration_facility: facility)
    end

    let!(:hypertensive_patients_registered_9_months_ago) do
      patients = create_list_in_period(
        :patient, 10,
        from_time: from_time - 9.months, to_time: (to_time - 9.months).prev_day,
        registration_facility: facility)

      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: patient.device_created_at, to_time: patient.device_created_at + 1.hour,
          patient: patient, facility: facility)
      end
      patients
    end

    let!(:patients_under_control_in_period) do
      patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(7)
      patients_under_control_in_period.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end
      patients_under_control_in_period
    end

    let!(:patients_not_under_control_in_period) do
      (hypertensive_patients_registered_9_months_ago - patients_under_control_in_period).each do |patient |
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: from_time, to_time: to_time,
          patient: patient, facility: patient.registration_facility)
      end
    end

    let!(:returning_patients) do
      patients = create_list_in_period(
        :patient, 5,
        from_time: 1.year.ago, to_time: from_time,
        registration_facility: facility)

      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :under_control, from_time: from_time, to_time: to_time,
          patient: patient, facility: facility)
      end

      patients
    end

    let!(:non_returning_hypertensive_patients) do
      patients = create_list_in_period(
        :patient, 10,
        from_time: from_time - 6.months, to_time: to_time - 6.months,
        registration_facility: facility)

      patients.each do |patient|
        create_in_period(
          :blood_pressure,
          trait: :hypertensive, from_time: patient.device_created_at, to_time: from_time,
          patient: patient, facility: facility)
      end
      patients
    end

    before :each do
      sign_in(owner)
      visit analytics_facility_path(facility)
    end

    it 'contains a link to the graphics page for facility group' do
      expect(page).to have_link(nil, href: analytics_facility_graphics_path(facility))
    end

    it 'contains the number of newly enrolled patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.newly_enrolled'))
      expect(page.find('#newly-enrolled-patients-count')).to have_content(5)
    end

    it 'contains the number of returning patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.return_patients'))
      expect(page.find('#returning-patients-count')).to have_content(15)
    end

    it 'contains the number of non returning hypertensive patients in the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.non_returning_hypertensive_patients'))
      expect(page.find('#non-returning-hypertensive-patients-count')).to have_content(13)
    end

    it 'contains a graph with number of non returning hypertensive patients per month' do
      expect(page).to have_css('#non-returning-hypertensive-patients-graph')
    end

    it 'contains the control rate for the last 90 days' do
      expect(page).to have_content(I18n.t('analytics.control_rate'))
      expect(page.find('#control-rate')).to have_content(70)
    end
  end
end
