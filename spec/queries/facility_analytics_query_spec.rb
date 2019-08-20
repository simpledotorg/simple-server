require 'rails_helper'

RSpec.describe FacilityAnalyticsQuery do
  let!(:users) { create_list(:user, 2) }
  let!(:facility) { create(:facility) }
  let!(:analytics) { FacilityAnalyticsQuery.new(facility) }

  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }
  let(:first_apr) { Date.new(2019, 4, 1) }
  let(:first_may) { Date.new(2019, 5, 1) }

  context 'when there is data available' do
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

    describe '#registered_patients_by_period' do
      it 'groups the registered patients by facility and beginning of month' do
        expected_result =
          { users.first.id =>
              { :registered_patients_by_period =>
                  { first_jan => 3,
                    first_feb => 3,
                  }
              },

            users.second.id =>
              { :registered_patients_by_period =>
                  { first_jan => 3,
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

    describe '#follow_up_patients_by_period' do
      it 'groups the follow up patients by facility and beginning of month' do
        expected_result =
          { users.first.id =>
              { :follow_up_patients_by_period =>
                  { first_feb => 6,
                    first_mar => 12,
                    first_apr => 6
                  }
              },

            users.second.id =>
              { :follow_up_patients_by_period =>
                  { first_feb => 6,
                    first_mar => 12,
                    first_apr => 6
                  }
              }
          }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end
  end

  context 'edge cases' do
    describe '#follow_up_patients_by_period' do
      it 'should discount counting as follow-up if the last BP is removed' do
        patient = Timecop.travel(first_feb) do
          create(:patient, registration_facility: facility, registration_user: users.first)
        end

        _mar_bp = Timecop.travel(first_mar) do
          create(:blood_pressure, patient: patient, facility: facility, user: users.first)
        end

        apr_bp = Timecop.travel(first_apr) do
          create(:blood_pressure, patient: patient, facility: facility, user: users.first)
        end

        # simulate soft-deleting a blood_pressure
        apr_bp.discard

        expected_result =
          { users.first.id =>
              { :follow_up_patients_by_period =>
                  {
                    first_mar => 1
                  }
              }
          }

        expect(analytics.follow_up_patients_by_period).to eq(expected_result)
      end
    end

    describe '#registered_patients_by_period' do
      it 'should count patients as registered even if they do not have a bp' do
        Timecop.travel(first_may) do
          create_list(:patient, 3, registration_facility: facility, registration_user: users.first)
        end

        expected_result =
          { users.first.id =>
              { :registered_patients_by_period =>
                  {
                    first_may => 3
                  }
              }
          }

        expect(analytics.registered_patients_by_period).to eq(expected_result)
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
