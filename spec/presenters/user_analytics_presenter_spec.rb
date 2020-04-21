require 'rails_helper'

RSpec.describe UserAnalyticsPresenter, type: :model do
  let!(:current_user) { create(:user) }
  let!(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

  describe '#statistics' do
    context 'daily' do
      let(:request_date) { Date.new(2018, 1, 1) }
      let(:reg_date) { request_date - 3.days }
      let(:follow_up_date) { request_date - 2.days }

      before do
        patients = create_list(:patient, 3, registration_facility: current_facility, recorded_at: reg_date)
        patients.each do |patient|
          create(:encounter,
                 :with_observables,
                 observable: create(:blood_pressure,
                                    patient: patient,
                                    facility: current_facility,
                                    user: current_user,
                                    recorded_at: follow_up_date))
        end

        stub_const("UserAnalyticsPresenter::DAYS_AGO", 6)
      end

      it 'has data grouped by date' do
        data =
          travel_to(request_date) do
            described_class.new(current_facility).statistics
          end

        expected_output = {
          registrations: {
            (request_date - 5.days) => 0,
            (request_date - 4.days) => 0,
            reg_date.to_date => 3,
            (request_date - 2.days) => 0,
            (request_date - 1.days) => 0,
            request_date => 0,
          },

          follow_ups: {
            (request_date - 5.days) => 0,
            (request_date - 4.days) => 0,
            (request_date - 3.days) => 0,
            follow_up_date.to_date => 3,
            (request_date - 1.days) => 0,
            request_date => 0,
          }
        }

        expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
      end

      it 'has no data if facility has not recorded anything recently' do
        data = described_class.new(current_facility).statistics

        expected_output = {
          registrations: {
            (Date.today - 5) => 0,
            (Date.today - 4) => 0,
            (Date.today - 3) => 0,
            (Date.today - 2) => 0,
            (Date.today - 1) => 0,
            Date.today => 0
          },

          follow_ups: {
            (Date.today - 5) => 0,
            (Date.today - 4) => 0,
            (Date.today - 3) => 0,
            (Date.today - 2) => 0,
            (Date.today - 1) => 0,
            Date.today => 0,
          }
        }

        expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
      end
    end

    context 'monthly' do
      let(:request_date) { Date.new(2018, 1, 1) }
      let(:reg_date) { request_date - 3.months }
      let(:follow_up_date) { request_date - 2.months }
      let(:controlled_follow_up_date) { request_date - 1.month }
      let(:gender) { 'female' }

      before do
        patients = create_list(:patient,
                               3,
                               registration_facility: current_facility,
                               recorded_at: reg_date,
                               gender: gender)
        patients.each do |patient|
          create(:encounter,
                 :with_observables,
                 observable: create(:blood_pressure,
                                    :critical,
                                    patient: patient,
                                    facility: current_facility,
                                    user: current_user,
                                    recorded_at: follow_up_date))

          create(:encounter,
                 :with_observables,
                 observable: create(:blood_pressure,
                                    :under_control,
                                    patient: patient,
                                    facility: current_facility,
                                    user: current_user,
                                    recorded_at: controlled_follow_up_date))
        end

        stub_const("UserAnalyticsPresenter::MONTHS_AGO", 6)
      end

      it 'has data grouped by date and gender' do
        data =
          travel_to(request_date) do
            described_class.new(current_facility).statistics
          end

        expected_output = {
          registrations: {
            [(request_date - 5.months), gender] => 0,
            [(request_date - 4.months), gender] => 0,
            [reg_date.to_date, gender] => 3,
            [(request_date - 2.months), gender] => 0,
            [controlled_follow_up_date.to_date, gender] => 0,
            [request_date, gender] => 0,
          },
          follow_ups: {
            [(request_date - 5.months), gender] => 0,
            [(request_date - 4.months), gender] => 0,
            [(request_date - 3.months), gender] => 0,
            [follow_up_date.to_date, gender] => 3,
            [controlled_follow_up_date.to_date, gender] => 3,
            [request_date, gender] => 0,
          }
        }

        expect(data.dig(:monthly, :grouped_by_gender_and_date)).to eq(expected_output)
      end

      it 'has data grouped by date' do
        data =
          travel_to(request_date) do
            described_class.new(current_facility).statistics
          end

        expected_output = {
          follow_ups: {
            (request_date - 5.months) => 0,
            (request_date - 4.months) => 0,
            (request_date - 3.months) => 0,
            (request_date - 2.months) => 3,
            (request_date - 1.months) => 3,
            request_date => 0,
          },

          registrations: {
            (request_date - 5.months) => 0,
            (request_date - 4.months) => 0,
            (request_date - 3.months) => 3,
            (request_date - 2.months) => 0,
            (request_date - 1.months) => 0,
            request_date => 0,
          },

          controlled_visits: {
            (request_date - 5.months) => 0,
            (request_date - 4.months) => 0,
            (request_date - 3.months) => 0,
            (request_date - 2.months) => 0,
            (request_date - 1.months) => 3,
            request_date => 0,
          }
        }

        expect(data.dig(:monthly, :grouped_by_date)).to eq(expected_output)
      end

      it 'has no data if facility has not recorded anything recently' do
        data = described_class.new(current_facility).statistics

        expected_output =
          {
            follow_ups: {},
            registrations: {}
          }

        expect(data.dig(:monthly, :grouped_by_gender_and_date)).to eq(expected_output)
      end
    end

    context 'all_time' do
      let(:request_date) { Date.new(2018, 1, 1) }
      let(:reg_date) { request_date - 3.months }
      let(:follow_up_date) { request_date - 2.months }
      let(:gender) { 'female' }

      before do
        patients = create_list(:patient,
                               3,
                               registration_facility: current_facility,
                               recorded_at: reg_date,
                               gender: gender)
        patients.each do |patient|
          create(:encounter,
                 :with_observables,
                 observable: create(:blood_pressure,
                                    patient: patient,
                                    facility: current_facility,
                                    user: current_user,
                                    recorded_at: follow_up_date))
        end
      end

      it 'has data grouped by gender' do
        data = described_class.new(current_facility).statistics

        expected_output = {
          follow_ups: {
            [follow_up_date, gender] => 3
          },

          registrations: {
            [reg_date, gender] => 3
          }
        }

        expect(data.dig(:all_time, :grouped_by_gender)).to eq(expected_output)
      end
    end

    context 'metadata' do
      context 'last_updated_at' do
        it 'has date for today if request was made today' do
          data = described_class.new(current_facility).statistics

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(Time.current.to_date)
        end

        it 'has the date at which the request was made' do
          two_days_ago = 2.days.ago.to_date

          data = travel_to(two_days_ago) do
            described_class.new(current_facility).statistics
          end

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(two_days_ago)
        end
      end

      it 'has the formatted_today_string (in the correct locale)' do
        current_locale = I18n.locale

        I18n.available_locales.each do |locale|
          I18n.locale = locale

          data = described_class.new(current_facility).statistics

          expect(data.dig(:metadata, :today_string))
            .to eq(I18n.t(:today_str))
        end

        # reset locale
        I18n.locale = current_locale
      end

      it 'has the formatted_next_date' do
        date = Date.new(2020, 1, 1)

        data = travel_to(date) do
          described_class.new(current_facility).statistics
        end

        expect(data.dig(:metadata, :formatted_next_date))
          .to eq('02-JAN-2020')
      end
    end

    context 'trophies' do
      it 'has both unlocked and the upcoming locked trophy' do
        #
        # create BPs (follow-ups)
        #
        patients = create_list(:patient, 3, registration_facility: current_facility)
        patients.each do |patient|
          [patient.recorded_at + 1.month,
           patient.recorded_at + 2.months,
           patient.recorded_at + 3.months,
           patient.recorded_at + 4.months].each do |date|
            travel_to(date) do
              create(:encounter,
                     :with_observables,
                     observable: create(:blood_pressure,
                                        patient: patient,
                                        facility: current_facility,
                                        user: current_user))
            end
          end
        end

        data = described_class.new(current_facility).statistics

        expected_output = {
          locked_trophy_value: 25,
          unlocked_trophy_values: [10]
        }

        expect(data[:trophies]).to eq(expected_output)
      end

      it 'has only 1 locked trophy if there are no achievements' do
        data = described_class.new(current_facility).statistics

        expected_output = {
          locked_trophy_value: 10,
          unlocked_trophy_values: []
        }

        expect(data[:trophies]).to eq(expected_output)
      end
    end
  end

  describe '#display_percentage' do
    it 'displays 0% if denominator is zero' do
      expect(described_class.new(current_facility).display_percentage(2, 0)).to eq("0%")
    end

    it 'displays 0% if denominator is nil' do
      expect(described_class.new(current_facility).display_percentage(2, nil)).to eq("0%")
    end

    it 'displays 0% if numerator is zero' do
      expect(described_class.new(current_facility).display_percentage(0, 3)).to eq("0%")
    end

    it 'displays 0% if numerator is nil' do
      expect(described_class.new(current_facility).display_percentage(nil, 2)).to eq("0%")
    end

    it 'displays the percentage rounded up' do
      expect(described_class.new(current_facility).display_percentage(22, 7)).to eq("314%")
    end
  end
end
