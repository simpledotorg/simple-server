require "rails_helper"

RSpec.describe UserAnalyticsPresenter, type: :model do
  let(:current_user) { create(:user) }
  let(:request_date) { Date.new(2018, 1, 1) }

  describe "#statistics" do
    context "when diabetes management is enabled" do
      let(:current_facility) {
        create(:facility,
          facility_group: current_user.facility.facility_group,
          enable_diabetes_management: true)
      }

      context "monthly" do
        let(:reg_date) { request_date - 2.months }
        let(:follow_up_date) { request_date - 1.month }
        let(:controlled_follow_up_date) { request_date }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              :critical,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_pressure,
              :with_encounter,
              :under_control,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: controlled_follow_up_date)
          end

          stub_const("UserAnalyticsPresenter::MONTHS_AGO", 3)
        end

        it "has data grouped by date and gender" do
          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            hypertension: {
              registrations: {
                [reg_date.to_date, "male"] => 1,
                [reg_date.to_date, "female"] => 1,

                [(request_date - 1.month), "male"] => 0,
                [(request_date - 1.month), "female"] => 0,

                [request_date, "male"] => 0,
                [request_date, "female"] => 0
              },

              follow_ups: {
                [(request_date - 2.months), "male"] => 0,
                [(request_date - 2.months), "female"] => 0,

                [follow_up_date.to_date, "male"] => 1,
                [follow_up_date.to_date, "female"] => 1,

                [controlled_follow_up_date.to_date, "male"] => 1,
                [controlled_follow_up_date.to_date, "female"] => 1
              }
            },

            diabetes: {
              registrations: {
                [reg_date.to_date, "transgender"] => 1,
                [(request_date - 1.month), "transgender"] => 0,
                [request_date, "transgender"] => 0
              },

              follow_ups: {
                [(request_date - 2.months), "transgender"] => 0,
                [follow_up_date.to_date, "transgender"] => 1,
                [request_date, "transgender"] => 0
              }
            }
          }

          expect(data.dig(:monthly, :grouped_by_date_and_gender)).to eq(expected_output)
        end

        it "has data grouped by date" do
          control_rate_service = double("ControlRateService")
          allow(ControlRateService).to receive(:new).and_return(control_rate_service)
          allow(control_rate_service).to receive(:call).and_return({control_rate: :statistics})

          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            htn_or_dm: {
              follow_ups: {
                (request_date - 2.months) => 0,
                (request_date - 1.months) => 3,
                request_date => 3
              },

              registrations: {
                (request_date - 2.months) => 3,
                (request_date - 1.months) => 0,
                request_date => 0
              }
            },

            hypertension: {
              follow_ups: {
                (request_date - 2.months) => 0,
                (request_date - 1.months) => 2,
                request_date => 2
              },

              registrations: {
                (request_date - 2.months) => 2,
                (request_date - 1.months) => 0,
                request_date => 0
              },

              controlled_visits: {
                control_rate: :statistics
              }
            },

            diabetes: {
              follow_ups: {
                (request_date - 2.months) => 0,
                (request_date - 1.months) => 1,
                request_date => 0
              },

              registrations: {
                (request_date - 2.months) => 1,
                (request_date - 1.months) => 0,
                request_date => 0
              }
            }
          }

          expect(data.dig(:monthly, :grouped_by_date)).to eq(expected_output)
        end

        it "fetches control rate data from the control rate service" do
          control_rate_service = double("ControlRateService")
          allow(ControlRateService).to receive(:new).and_return(control_rate_service)
          allow(control_rate_service).to receive(:call).and_return(control_rate: :statistics)

          control_rate_start = Period.month(request_date - 12.months)
          control_rate_end = Period.month(request_date - 1.month)
          expect(ControlRateService).to receive(:new).with(
            current_facility,
            periods: control_rate_start..control_rate_end
          )

          travel_to(request_date) {
            described_class.new(current_facility).statistics
          }
        end

        it "fetches cohort data from the cohort service" do
          cohort_service = double("CohortService")
          allow(CohortService).to receive(:new).and_return(cohort_service)
          allow(cohort_service).to receive(:totals).and_return(cohort: :statistics)

          expect(CohortService).to receive(:new).with(
            region: current_facility,
            quarters: Quarter.new(date: request_date).previous_quarter.downto(3)
          )

          travel_to(request_date) {
            described_class.new(current_facility).statistics
          }
        end

        it "has no data if facility has not recorded anything recently" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            hypertension: {
              follow_ups: {},
              registrations: {}
            },

            diabetes: {
              follow_ups: {},
              registrations: {}
            }
          }
          expect(data.dig(:monthly, :grouped_by_date_and_gender)).to eq(expected_output)
        end
      end

      context "daily" do
        let(:reg_date) { request_date - 3.days }
        let(:follow_up_date) { request_date - 2.days }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date)]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end

          stub_const("UserAnalyticsPresenter::DAYS_AGO", 6)
        end

        it "has data grouped by date" do
          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            registrations: {
              (request_date - 5.days) => 0,
              (request_date - 4.days) => 0,
              reg_date.to_date => 3,
              (request_date - 2.days) => 0,
              (request_date - 1.days) => 0,
              request_date => 0
            },

            follow_ups: {
              (request_date - 5.days) => 0,
              (request_date - 4.days) => 0,
              (request_date - 3.days) => 0,
              follow_up_date.to_date => 3,
              (request_date - 1.days) => 0,
              request_date => 0
            }
          }

          expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
        end

        it "has no data if facility has not recorded anything recently" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            registrations: {
              (Date.current - 5) => 0,
              (Date.current - 4) => 0,
              (Date.current - 3) => 0,
              (Date.current - 2) => 0,
              (Date.current - 1) => 0,
              Date.current => 0
            },

            follow_ups: {
              (Date.current - 5) => 0,
              (Date.current - 4) => 0,
              (Date.current - 3) => 0,
              (Date.current - 2) => 0,
              (Date.current - 1) => 0,
              Date.current => 0
            }
          }

          expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
        end
      end

      context "all_time" do
        let(:reg_date) { request_date - 3.months }
        let(:follow_up_date) { request_date - 2.months }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end
        end

        it "has data grouped by gender" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            hypertension: {
              follow_ups: {
                "female" => 1,
                "male" => 1
              },

              registrations: {
                "female" => 1,
                "male" => 1
              }
            },

            diabetes: {
              follow_ups: {
                "transgender" => 1
              },

              registrations: {
                "transgender" => 1
              }
            }
          }

          expect(data.dig(:all_time, :grouped_by_gender)).to eq(expected_output)
        end

        it "has data grouped by date" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            htn_or_dm: {
              follow_ups: 3,
              registrations: 3
            }
          }

          expect(data.dig(:all_time, :grouped_by_date)).to eq(expected_output)
        end
      end
    end

    context "when diabetes management is disabled" do
      let(:current_facility) {
        create(:facility,
          facility_group: current_user.facility.facility_group,
          enable_diabetes_management: false)
      }

      context "monthly" do
        let(:reg_date) { request_date - 2.months }
        let(:follow_up_date) { request_date - 1.month }
        let(:controlled_follow_up_date) { request_date }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              :critical,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_pressure,
              :under_control,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: controlled_follow_up_date)
          end

          stub_const("UserAnalyticsPresenter::MONTHS_AGO", 3)
        end

        it "has data grouped by date and gender" do
          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            hypertension: {
              registrations: {
                [reg_date.to_date, "male"] => 1,
                [reg_date.to_date, "female"] => 1,

                [(request_date - 1.month), "male"] => 0,
                [(request_date - 1.month), "female"] => 0,

                [request_date, "male"] => 0,
                [request_date, "female"] => 0
              },

              follow_ups: {
                [(request_date - 2.months), "male"] => 0,
                [(request_date - 2.months), "female"] => 0,

                [follow_up_date.to_date, "male"] => 1,
                [follow_up_date.to_date, "female"] => 1,

                [controlled_follow_up_date.to_date, "male"] => 1,
                [controlled_follow_up_date.to_date, "female"] => 1
              }
            }
          }

          expect(data.dig(:monthly, :grouped_by_date_and_gender)).to eq(expected_output)
        end

        it "has data grouped by date" do
          control_rate_service = double("ControlRateService")
          allow(ControlRateService).to receive(:new).and_return(control_rate_service)
          allow(control_rate_service).to receive(:call).and_return({control_rate: :statistics})

          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            hypertension: {
              follow_ups: {
                (request_date - 2.months) => 0,
                (request_date - 1.months) => 2,
                request_date => 2
              },

              registrations: {
                (request_date - 2.months) => 2,
                (request_date - 1.months) => 0,
                request_date => 0
              },

              controlled_visits: {
                control_rate: :statistics
              }
            }
          }

          expect(data.dig(:monthly, :grouped_by_date)).to eq(expected_output)
        end

        it "has no data if facility has not recorded anything recently" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            hypertension: {
              follow_ups: {},
              registrations: {}
            }
          }
          expect(data.dig(:monthly, :grouped_by_date_and_gender)).to eq(expected_output)
        end
      end

      context "daily" do
        let(:reg_date) { request_date - 3.days }
        let(:follow_up_date) { request_date - 2.days }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date)]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end

          stub_const("UserAnalyticsPresenter::DAYS_AGO", 6)
        end

        it "has data grouped by date" do
          data =
            travel_to(request_date) {
              described_class.new(current_facility).statistics
            }

          expected_output = {
            registrations: {
              (request_date - 5.days) => 0,
              (request_date - 4.days) => 0,
              reg_date.to_date => 2,
              (request_date - 2.days) => 0,
              (request_date - 1.days) => 0,
              request_date => 0
            },

            follow_ups: {
              (request_date - 5.days) => 0,
              (request_date - 4.days) => 0,
              (request_date - 3.days) => 0,
              follow_up_date.to_date => 2,
              (request_date - 1.days) => 0,
              request_date => 0
            }
          }

          expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
        end

        it "has no data if facility has not recorded anything recently" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            registrations: {
              (Date.current - 5) => 0,
              (Date.current - 4) => 0,
              (Date.current - 3) => 0,
              (Date.current - 2) => 0,
              (Date.current - 1) => 0,
              Date.current => 0
            },

            follow_ups: {
              (Date.current - 5) => 0,
              (Date.current - 4) => 0,
              (Date.current - 3) => 0,
              (Date.current - 2) => 0,
              (Date.current - 1) => 0,
              Date.current => 0
            }
          }

          expect(data.dig(:daily, :grouped_by_date)).to eq(expected_output)
        end
      end

      context "all_time" do
        let(:reg_date) { request_date - 3.months }
        let(:follow_up_date) { request_date - 2.months }

        before do
          patients = [create(:patient,
            :hypertension,
            registration_facility: current_facility,
            recorded_at: reg_date,
            gender: "female"),
            create(:patient,
              :hypertension,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "male"),
            create(:patient,
              :diabetes,
              registration_facility: current_facility,
              recorded_at: reg_date,
              gender: "transgender")]

          patients.each do |patient|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)

            create(:blood_sugar,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              user: current_user,
              recorded_at: follow_up_date)
          end
        end

        it "has data grouped by gender" do
          data = described_class.new(current_facility).statistics

          expected_output = {
            hypertension: {
              follow_ups: {
                "female" => 1,
                "male" => 1
              },

              registrations: {
                "female" => 1,
                "male" => 1
              }
            }
          }

          expect(data.dig(:all_time, :grouped_by_gender)).to eq(expected_output)
        end

        it "has data grouped by date" do
          data = described_class.new(current_facility).statistics

          expect(data.dig(:all_time, :grouped_by_date)).to eq(nil)
        end
      end
    end

    context "metadata" do
      let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

      context "last_updated_at" do
        it "has date for today if request was made today" do
          data = described_class.new(current_facility).statistics

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(Time.current.to_date)
        end

        it "has the date at which the request was made" do
          two_days_ago = 2.days.ago.to_date

          data = travel_to(two_days_ago) {
            described_class.new(current_facility).statistics
          }

          expect(data.dig(:metadata, :last_updated_at).to_date)
            .to eq(two_days_ago)
        end
      end

      context "formatted_today_string" do
        before do
          @current_locale = I18n.locale
        end

        after do
          I18n.locale = @current_locale
        end

        I18n.available_locales.each do |locale|
          it "is in #{locale}" do
            I18n.locale = locale
            data = described_class.new(current_facility).statistics

            expect(data.dig(:metadata, :today_string)).to eq(I18n.t(:today_str, locale: locale))
          end
        end
      end

      it "has the formatted_next_date" do
        date = Date.new(2020, 1, 1)

        data = travel_to(date) {
          described_class.new(current_facility).statistics
        }

        expect(data.dig(:metadata, :formatted_next_date))
          .to eq("02-JAN-2020")
      end
    end

    context "trophies" do
      let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

      it "has both unlocked and the upcoming locked trophy" do
        #
        # create BPs (hypertension follow-ups)
        #
        patients = create_list(:patient, 3, :hypertension, registration_facility: current_facility)
        patients.each do |patient|
          [patient.recorded_at + 1.months,
            patient.recorded_at + 2.months,
            patient.recorded_at + 3.months,
            patient.recorded_at + 4.months].each do |date|
            create(:blood_pressure,
              :with_encounter,
              patient: patient,
              facility: current_facility,
              recorded_at: date,
              user: current_user)
          end
        end

        data = described_class.new(current_facility).statistics

        expected_output = {
          locked_trophy_value: 25,
          unlocked_trophy_values: [10]
        }

        expect(data[:trophies]).to eq(expected_output)
      end

      it "has only 1 locked trophy if there are no achievements" do
        data = described_class.new(current_facility).statistics

        expected_output = {
          locked_trophy_value: 10,
          unlocked_trophy_values: []
        }

        expect(data[:trophies]).to eq(expected_output)
      end

      context "unlocks additional trophies" do
        it "unlocks a milestone of 10_000 if follow_ups are 5_000" do
          user_analytics = described_class.new(current_facility)

          all_time_htn_stats = {grouped_by_gender: {hypertension: {follow_ups: {"male" => 5_000}}}}
          allow(user_analytics).to receive(:all_time_htn_stats).and_return(all_time_htn_stats)

          expected_output = {
            locked_trophy_value: 10_000,
            unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
          }

          expect(user_analytics.statistics[:trophies]).to eq(expected_output)
        end

        it "unlocks a milestone of 10_000 if follow_ups are between 5_000...10_000" do
          user_analytics = described_class.new(current_facility)

          all_time_htn_stats = {grouped_by_gender: {hypertension: {follow_ups: {"male" => 5_001}}}}
          allow(user_analytics).to receive(:all_time_htn_stats).and_return(all_time_htn_stats)

          expected_output = {
            locked_trophy_value: 10_000,
            unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
          }

          expect(user_analytics.statistics[:trophies]).to eq(expected_output)
        end

        it "unlocks milestones in increments of 10_000 after reaching 10_000" do
          user_analytics = described_class.new(current_facility)

          all_time_htn_stats = {grouped_by_gender: {hypertension: {follow_ups: {"male" => 10_000}}}}
          allow(user_analytics).to receive(:all_time_htn_stats).and_return(all_time_htn_stats)

          expected_output = {
            locked_trophy_value: 20_000,
            unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000, 10_000]
          }

          expect(user_analytics.statistics[:trophies]).to eq(expected_output)
        end
      end
    end
  end

  describe "#display_percentage" do
    let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

    it "displays 0% if denominator is zero" do
      expect(described_class.new(current_facility).display_percentage(2, 0)).to eq("0%")
    end

    it "displays 0% if denominator is nil" do
      expect(described_class.new(current_facility).display_percentage(2, nil)).to eq("0%")
    end

    it "displays 0% if numerator is zero" do
      expect(described_class.new(current_facility).display_percentage(0, 3)).to eq("0%")
    end

    it "displays 0% if numerator is nil" do
      expect(described_class.new(current_facility).display_percentage(nil, 2)).to eq("0%")
    end

    it "displays the percentage rounded up" do
      expect(described_class.new(current_facility).display_percentage(22, 7)).to eq("314%")
    end
  end
end
