# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityAnalyticsQuery do
  let!(:users) { create_list(:user, 2) }
  let!(:facility) { create(:facility) }
  let!(:analytics) { FacilityAnalyticsQuery.new(facility, :month, 6) }
  let!(:current_month) { Date.current.beginning_of_month }

  let(:five_months_back) { current_month - 5.months }
  let(:four_months_back) { current_month - 4.months }
  let(:three_months_back) { current_month - 3.months }
  let(:two_months_back) { current_month - 2.months }
  let(:one_month_back) { current_month - 1.months }

  context "when there is data available" do
    before do
      [five_months_back, four_months_back].each do |month|
        #
        # register patients
        #
        registered_patients = Timecop.travel(month) {
          patients = []

          users.each do |u|
            patients << create_list(:patient, 3, registration_facility: facility, registration_user: u)
          end

          patients << create(:patient, :without_hypertension, registration_facility: facility, registration_user: users.first)

          patients.flatten
        }

        #
        # add blood_pressures next month
        #
        Timecop.travel(month + 1.month) do
          users.each do |u|
            registered_patients.each do |patient|
              create(:blood_pressure,
                patient: patient,
                facility: facility,
                user: u)
            end
          end
        end

        #
        # add blood_pressures after a couple of months
        #
        Timecop.travel(month + 2.months) do
          users.each do |u|
            registered_patients.each do |patient|
              create(:blood_pressure,
                patient: patient,
                facility: facility,
                user: u)
            end
          end
        end
      end
    end

    describe "#registered_patients_by_period" do
      context "considers only htn diagnosed patients" do
        it "groups the registered patients by facility and beginning of month" do
          expected_result =
            {users.first.id =>
                {registered_patients_by_period: {five_months_back => 3,
                                                 four_months_back => 3}},

             users.second.id =>
                {registered_patients_by_period: {five_months_back => 3,
                                                 four_months_back => 3}}}

          expect(analytics.registered_patients_by_period).to eq(expected_result)
        end
      end
    end

    describe "#total_registered_patients" do
      context "considers only htn diagnosed patients" do
        it "groups the registered patients by facility and beginning of month" do
          expected_result =
            {users.first.id =>
                {
                  total_registered_patients: 6
                },
             users.second.id =>
                {
                  total_registered_patients: 6
                }}

          expect(analytics.total_registered_patients).to eq(expected_result)
        end
      end
    end

    describe "#follow_up_patients_by_period" do
      it "groups the follow up patients by users within a facility and by period" do
        expected_result =
          {
            users[0].id =>
              {follow_up_patients_by_period: {four_months_back => 6,
                                              three_months_back => 12,
                                              two_months_back => 6}},
            users[1].id =>
              {follow_up_patients_by_period: {four_months_back => 6,
                                              three_months_back => 12,
                                              two_months_back => 6}}
          }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end
  end

  context "edge cases" do
    describe "#follow_up_patients_by_period" do
      it "should discount counting as follow-up if the last BP is removed" do
        patient = Timecop.travel(four_months_back) {
          create(:patient, :hypertension, registration_facility: facility, registration_user: users.first)
        }

        _mar_bp = Timecop.travel(three_months_back) {
          create(:blood_pressure, patient: patient, facility: facility, user: users.first)
        }

        apr_bp = Timecop.travel(two_months_back) {
          create(:blood_pressure, patient: patient, facility: facility, user: users.first)
        }

        # simulate soft-deleting a blood_pressure
        apr_bp.discard

        expected_result =
          {users.first.id =>
              {follow_up_patients_by_period: {
                three_months_back => 1
              }}}

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end

    describe "#registered_patients_by_period" do
      it "should count patients as registered even if they do not have a bp" do
        Timecop.travel(one_month_back) do
          create_list(:patient, 3, :hypertension, registration_facility: facility, registration_user: users.first)
        end

        expected_result =
          {users.first.id =>
              {registered_patients_by_period: {
                one_month_back => 3
              }}}

        expect(analytics.registered_patients_by_period).to eq(expected_result)
      end
    end
  end

  context "when there is no data available" do
    it "returns nil for all analytics queries" do
      expect(analytics.registered_patients_by_period).to eq(nil)
      expect(analytics.total_registered_patients).to eq(nil)
      expect(analytics.follow_up_patients_by_period).to eq(nil)
    end
  end

  context "for discarded patients" do
    let!(:patients) do
      Timecop.travel(four_months_back) {
        create_list(:patient,
          2,
          :hypertension,
          registration_facility: facility,
          registration_user: users.first)
      }
    end

    before do
      Timecop.travel(three_months_back) do
        create(:blood_pressure, patient: patients.first, facility: facility, user: users.first)
        create(:blood_pressure, patient: patients.second, facility: facility, user: users.first)
      end
      patients.first.discard_data
    end

    describe "#registered_patients_by_period" do
      it "shouldn't count discarded patients" do
        expected_result =
          {users.first.id =>
              {registered_patients_by_period: {
                four_months_back => 1
              }}}

        expect(analytics.registered_patients_by_period).to eq(expected_result)
      end
    end

    describe "#follow_up_patients_by_period" do
      let!(:expected_result) do
        {users.first.id =>
            {follow_up_patients_by_period: {
              three_months_back => 1
            }}}
      end

      it "shouldn't count discarded patients" do
        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end

    describe "#total_registered_patients" do
      let!(:expected_result) do
        {users.first.id =>
            {
              total_registered_patients: 1
            }}
      end

      it "shouldn't count discarded patients" do
        expect(analytics.total_registered_patients).to eq(expected_result)
      end
    end
  end
end
