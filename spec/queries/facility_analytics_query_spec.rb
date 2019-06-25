require 'rails_helper'

RSpec.describe FacilityAnalyticsQuery do
  let!(:users) { create_list(:user, 2) }
  let!(:facility) { create(:facility) }
  let!(:analytics) { FacilityAnalyticsQuery.new(facility: facility) }

  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }
  let(:first_apr) { Date.new(2019, 4, 1) }

  before do
    [first_jan, first_feb].each do |month|
      #
      # register patients
      #
      registered_patients = Timecop.travel(month) do
        patients = []

        users.each do |u|
          patients << create_list(:patient, 3, registration_facility: facility, registration_user: u)
        end

        patients.flatten
      end

      #
      # add blood_pressures next month
      #
      Timecop.travel(month + 1.month) do
        users.each do |u|
          registered_patients.each { |patient| create(:blood_pressure,
                                                      patient: patient,
                                                      facility: facility,
                                                      user: u) }
        end
      end

      #
      # add blood_pressures after a couple of months
      #
      Timecop.travel(month + 2.months) do
        users.each do |u|
          registered_patients.each { |patient| create(:blood_pressure,
                                                      patient: patient,
                                                      facility: facility,
                                                      user: u) }
        end
      end
    end
  end

  describe '#follow_up_patients_by_month' do
    it 'groups the follow up patients by facility and beginning of month' do
      expected_result =
        { users.first.id =>
            { :follow_up_patients_by_month =>
                { first_feb => 6,
                  first_mar => 12,
                  first_apr => 6
                }
            },

          users.second.id =>
            { :follow_up_patients_by_month =>
                { first_feb => 6,
                  first_mar => 12,
                  first_apr => 6
                }
            }
        }

      expect(analytics.follow_up_patients_by_month).to eq(expected_result)
    end
  end

  describe '#registered_patients_by_month' do
    it 'groups the registered patients by facility and beginning of month' do
      expected_result =
        { users.first.id =>
            { :registered_patients_by_month =>
                { first_jan => 3,
                  first_feb => 3,
                }
            },

          users.second.id =>
            { :registered_patients_by_month =>
                { first_jan => 3,
                  first_feb => 3,
                }
            }
        }

      expect(analytics.registered_patients_by_month).to eq(expected_result)
    end
  end

  describe '#total_registered_patients' do
    it 'groups the registered patients by facility and beginning of month' do
      expected_result =
        { users.first.id =>
            {
              :total_registered_patients => 6
            },
          users.second.id =>
            {
              :total_registered_patients => 6
            }
        }

      expect(analytics.total_registered_patients).to eq(expected_result)
    end
  end
end
