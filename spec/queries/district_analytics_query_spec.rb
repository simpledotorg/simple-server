require "rails_helper"

RSpec.describe DistrictAnalyticsQuery do
  let(:organization) { create(:organization) }
  let!(:facility_group) { create(:facility_group, name: "Bathinda", organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group) }
  let!(:facility_2) { create(:facility, facility_group: facility_group) }
  let!(:facility_3) { create(:facility, facility_group: facility_group) }
  let!(:analytics) { DistrictAnalyticsQuery.new(facility_group, :month, 5) }
  let!(:current_month) { Date.current.beginning_of_month }

  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  let(:four_months_back) { current_month - 4.months }
  let(:three_months_back) { current_month - 3.months }
  let(:two_months_back) { current_month - 2.months }
  let(:one_month_back) { current_month - 1.months }

  context "when there is data available" do
    before do
      [four_months_back, three_months_back].each do |month|
        # register patients in facility_1 and assign it facility_2
        patients_1 = Timecop.travel(month) {
          create_list(:patient, 3, :hypertension, registration_facility: facility_1, registration_user: user, assigned_facility: facility_2)
        }
        # register patients in facility_2 and assign it facility_3
        patients_2 = Timecop.travel(month) {
          create_list(:patient, 3, :hypertension, registration_facility: facility_2, registration_user: user, assigned_facility: facility_3)
        }
        # register patient without HTN in facility_2
        Timecop.travel(month) do
          create(:patient, :without_hypertension, registration_user: user, registration_facility: facility_2)
        end
        # add blood_pressures next month to facility_1 & facility_2
        Timecop.travel(month + 1.month) do
          patients_1.each do |patient|
            create(:bp_with_encounter, patient: patient, facility: facility_1, user: user)
          end

          patients_2.each do |patient|
            create(:bp_with_encounter, patient: patient, facility: facility_2, user: user)
          end
        end
        # add blood_pressures after a couple of months to facility_1 & facility_2
        Timecop.travel(month + 2.months) do
          patients_1.each { |patient| create(:bp_with_encounter, patient: patient, facility: facility_1, user: user) }
          patients_2.each { |patient| create(:bp_with_encounter, patient: patient, facility: facility_2, user: user) }
        end
      end
    end

    describe "#call" do
      it "returns aggregated data for all facilities in the district" do
        expected = {
          facility_1.id => {
            total_registered_patients: 6,
            registered_patients_by_period: {
              four_months_back => 3,
              three_months_back => 3,
              two_months_back => 0,
              one_month_back => 0
            },
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          },
          facility_2.id => {
            total_assigned_patients: 6,
            total_registered_patients: 6,
            registered_patients_by_period: {
              four_months_back => 3,
              three_months_back => 3,
              two_months_back => 0,
              one_month_back => 0
            },
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          },
          facility_3.id => {
            total_assigned_patients: 6,
            total_registered_patients: 0,
            registered_patients_by_period: {
              four_months_back => 0,
              three_months_back => 0,
              two_months_back => 0,
              one_month_back => 0
            }
          }
        }
        refresh_views

        with_reporting_time_zone do
          result = analytics.call
          expect(result[facility_1.id]).to eq(expected[facility_1.id])
          expect(result[facility_2.id]).to eq(expected[facility_2.id])
          expect(result[facility_3.id]).to eq(expected[facility_3.id])
        end
      end
    end

    describe "#registered_patients_by_period" do
      context "considers only htn diagnosed patients" do
        it "groups the registered patients by facility and beginning of month" do
          expected =
            {
              facility_1.id =>
                {
                  registered_patients_by_period: {
                    four_months_back => 3,
                    three_months_back => 3,
                    two_months_back => 0,
                    one_month_back => 0
                  }
                },
              facility_2.id =>
                {
                  registered_patients_by_period: {
                    four_months_back => 3,
                    three_months_back => 3,
                    two_months_back => 0,
                    one_month_back => 0
                  }
                }
            }

          refresh_views
          with_reporting_time_zone do
            result = analytics.call
            expect(result[facility_1.id][:registered_patients_by_period]).to eq(expected[facility_1.id][:registered_patients_by_period])
            expect(result[facility_2.id][:registered_patients_by_period]).to eq(expected[facility_2.id][:registered_patients_by_period])
          end
        end
      end
    end

    describe "#total_registered_patients" do
      context "considers only htn diagnosed patients" do
        it "groups patients by registration facility" do
          expected_result =
            {
              facility_1.id => {total_registered_patients: 6},
              facility_2.id => {total_registered_patients: 6},
              facility_3.id => {total_registered_patients: 0}
            }
          refresh_views

          with_reporting_time_zone do
            expect(analytics.total_registered_patients).to eq(expected_result)
          end
        end
      end
    end

    describe "#follow_up_patients_by_period" do
      it "counts follow up BPs recorded at the facility in the period" do
        expected_result = {
          facility_1.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          },

          facility_2.id => {
            follow_up_patients_by_period: {
              three_months_back => 3,
              two_months_back => 6,
              one_month_back => 3
            }
          }
        }
        refresh_views

        with_reporting_time_zone do
          expect(analytics.follow_up_patients_by_period).to eq(expected_result)
        end
      end
    end

    context "facilities in the same district but belonging to different organizations" do
      let!(:facility_in_another_org) { create(:facility) }
      let!(:bp_in_another_org) { create(:bp_with_encounter, facility: facility_in_another_org) }

      it "does not contain data from a different organization" do
        refresh_views
        expect(analytics.registered_patients_by_period.keys).not_to include(facility_in_another_org.id)
        expect(analytics.total_registered_patients.keys).not_to include(facility_in_another_org.id)
        expect(analytics.follow_up_patients_by_period.keys).not_to include(facility_in_another_org.id)
      end
    end
  end

  context "when there is no data available" do
    it "returns nil for all analytics queries" do
      refresh_views
      expect(analytics.total_registered_patients[facility_1.id]).to eq(total_registered_patients: 0)
    end
  end

  context "for discarded patients" do
    let!(:patients) do
      Timecop.travel(four_months_back) do
        create_list(
          :patient,
          2,
          :hypertension,
          registration_facility: facility_2,
          registration_user: user
        )
      end
    end

    before do
      Timecop.travel(three_months_back) do
        create(:bp_with_encounter, patient: patients.first, facility: facility_2, user: user)
        create(:bp_with_encounter, patient: patients.second, facility: facility_2, user: user)
      end

      patients.first.discard_data
      refresh_views
    end

    describe "#registered_patients_by_period" do
      it "excludes discarded patients" do
        expected_result = {
          facility_2.id =>
            {
              registered_patients_by_period: {
                four_months_back => 1,
                three_months_back => 0,
                two_months_back => 0,
                one_month_back => 0
              }
            }
        }

        expect(analytics.registered_patients_by_period).to eq(expected_result)
      end
    end

    describe "#follow_up_patients_by_period" do
      it "excludes discarded patients" do
        expected_result = {
          facility_2.id =>
            {
              follow_up_patients_by_period: {
                three_months_back => 1
              }
            }
        }

        with_reporting_time_zone do
          result = analytics.follow_up_patients_by_period
          expect(result).to eq(expected_result)
        end
      end
    end
  end

  describe "#total_assigned_patients" do
    it "returns total assigned patients sorted by facility id" do
      create(:patient, :hypertension, assigned_facility: facility_1)
      expected_result = {
        facility_1.id => {total_assigned_patients: 1}
      }
      refresh_views

      expect(analytics.total_assigned_patients).to eq(expected_result)
    end
  end
end
