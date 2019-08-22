require 'rails_helper'

RSpec.describe DistrictAnalyticsQuery do
  let!(:organization) { create(:organization) }
  let!(:facility_group) { create(:facility_group, organization: organization)}
  let!(:district_name) { "Bathinda" }
  let!(:facility) { create(:facility, facility_group: facility_group, district: district_name) }
  let!(:analytics) { DistrictAnalyticsQuery.new(district_name, organization) }

  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }
  let(:first_apr) { Date.new(2019, 4, 1) }

  context 'when there is data available' do
    before do
      [first_jan, first_feb].each do |month|
        #
        # register patients
        #
        registered_patients_on_jan = Timecop.travel(month) do
          create_list(:patient, 3, registration_facility: facility)
        end

        #
        # add blood_pressures next month
        #
        Timecop.travel(month + 1.month) do
          registered_patients_on_jan.each { |patient| create(:blood_pressure, patient: patient, facility: facility) }
        end

        #
        # add blood_pressures after a couple of months
        #
        Timecop.travel(month + 2.months) do
          registered_patients_on_jan.each { |patient| create(:blood_pressure, patient: patient, facility: facility) }
        end
      end
    end

    describe '#registered_patients_by_period' do
      it 'groups the registered patients by facility and beginning of month' do
        expected_result =
          { facility.id =>
              { :registered_patients_by_period =>
                  {
                    first_jan => 3,
                    first_feb => 3,
                  }
              }
          }

        expect(analytics.registered_patients_by_period).to eq(expected_result)
      end
    end

    describe '#total_registered_patients' do
      it 'groups the registered patients by facility and beginning of month' do
        expected_result =
          { facility.id =>
              {
                :total_registered_patients => 6
              }
          }

        expect(analytics.total_registered_patients).to eq(expected_result)
      end
    end

    describe '#follow_up_patients_by_period' do
      it 'groups the follow up patients by facility and beginning of month' do
        expected_result =
          { facility.id =>
              { :follow_up_patients_by_period =>
                  { first_feb => 3,
                    first_mar => 6,
                    first_apr => 3
                  }
              }
          }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end

    context 'facilities in the same district but belonging to different organizations' do
      let!(:facility_in_another_org) { create(:facility) }
      let!(:bp_in_another_org) { create(:blood_pressure, facility: facility_in_another_org) }
      it 'does not contain data from a different organization' do
        expect(analytics.registered_patients_by_period.keys).not_to include(facility_in_another_org.id)
        expect(analytics.total_registered_patients.keys).not_to include(facility_in_another_org.id)
        expect(analytics.follow_up_patients_by_period.keys).not_to include(facility_in_another_org.id)
      end
    end
  end

  context 'when there is no data available' do
    it 'returns nil for all analytics queries' do
      expect(analytics.registered_patients_by_period).to eq(nil)
      expect(analytics.total_registered_patients).to eq(nil)
      expect(analytics.follow_up_patients_by_period).to eq(nil)
    end
  end
end
