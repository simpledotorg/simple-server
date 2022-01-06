# frozen_string_literal: true

require "rails_helper"

RSpec.describe FollowUpsQuery do
  context "#hypertension_follow_ups" do
    it "counts follow_ups only for hypertensive patients" do
      registration_date = Time.new(2018, 4, 8)
      first_follow_up_date = registration_date + 1.month
      second_follow_up_date = first_follow_up_date + 1.month

      facility = create(:facility)
      dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
      htn_patient = create(:patient, recorded_at: registration_date)

      create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
      create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
      create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
      create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date + 1.day)
      create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

      expected_output = {
        second_follow_up_date.to_date.beginning_of_month => 1
      }
      expected_repo_output = {
        Period.month(second_follow_up_date) => 1
      }

      region = facility.region
      periods = Range.new(registration_date.to_period, second_follow_up_date.to_period)
      repository = Reports::Repository.new(region, periods: periods)

      expect(facility.hypertension_follow_ups_by_period(:month).count).to eq(expected_output)
      expect(repository.hypertension_follow_ups[facility.region.slug]).to eq(expected_repo_output)
    end

    it "counts the patients' hypertension follow ups at the facility only" do
      facility_1, facility_2 = create_list(:facility, 2)
      patient = create(:patient, :hypertension, recorded_at: 10.months.ago)

      create(:blood_pressure, :with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient)
      create(:blood_pressure, :with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient)

      expect(facility_1.hypertension_follow_ups_by_period(:month, last: 4).count[1.month.ago.beginning_of_month.to_date]).to eq 0
      expect(facility_2.hypertension_follow_ups_by_period(:month, last: 4).count[3.months.ago.beginning_of_month.to_date]).to eq 0

      expect(facility_1.hypertension_follow_ups_by_period(:month, last: 4).count[3.month.ago.beginning_of_month.to_date]).to eq 1
      expect(facility_2.hypertension_follow_ups_by_period(:month, last: 4).count[1.months.ago.beginning_of_month.to_date]).to eq 1
    end

    xit "can add additional grouping criteria" do
      facility_1, facility_2 = create_list(:facility, 2)
      user_1, user_2 = *create_list(:user, 2)

      patient = create(:patient, :hypertension, recorded_at: 10.months.ago)
      patient_2 = create(:patient, :hypertension, recorded_at: 10.months.ago)

      Timecop.freeze("May 1st 2021") do
        create(:blood_pressure, recorded_at: "February 10th 2021", facility: facility_1, patient: patient, user: user_1)
        create(:blood_pressure, recorded_at: "March 5th 2021", facility: facility_1, patient: patient, user: user_1)
        create(:blood_pressure, recorded_at: "March 5th 2021", facility: facility_1, patient: patient_2, user: user_1)
        create(:blood_pressure, recorded_at: "March 20th 2021", facility: facility_1, patient: patient, user: user_2)
        create(:blood_pressure, recorded_at: 1.month.ago, facility: facility_2, patient: patient)

        result = described_class.new.hypertension(facility_1, :month, group_by: "blood_pressures.user_id")
        expected = {
          Period.month("Feb 1st 2021") => {user_1.id => 1, user_2.id => 0},
          Period.month("March 1st 2021") => {user_1.id => 2, user_2.id => 1}
        }
        expect(result).to eq(expected)
      end
    end
  end

  context "follow ups" do
    let(:reg_date) { Date.new(2018, 1, 1) }
    let(:first_follow_up_date) { reg_date + 1.month }
    let(:second_follow_up_date) { first_follow_up_date + 1.day }
    let(:current_user) { create(:user) }
    let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
    let(:follow_up_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
    let(:hypertensive_patient) { create(:patient, registration_facility: current_facility, recorded_at: reg_date) }
    let(:diabetic_patient) { create(:patient, :diabetes, registration_facility: current_facility, recorded_at: reg_date) }

    before do
      2.times do
        create(:blood_sugar,
          :with_encounter,
          facility: current_facility,
          patient: diabetic_patient,
          user: current_user,
          recorded_at: first_follow_up_date)
        create(:blood_pressure,
          :with_encounter,
          patient: hypertensive_patient,
          facility: current_facility,
          user: current_user,
          recorded_at: first_follow_up_date)
      end

      # visit at a facility different from registration
      create(:blood_pressure,
        :with_encounter,
        patient: hypertensive_patient,
        facility: follow_up_facility,
        user: current_user,
        recorded_at: first_follow_up_date)

      # diabetic patient following up with a BP
      create(:blood_pressure,
        :with_encounter,
        patient: diabetic_patient,
        facility: current_facility,
        user: current_user,
        recorded_at: first_follow_up_date)

      # another follow up in the same month but another day
      create(:blood_pressure,
        :with_encounter,
        patient: hypertensive_patient,
        facility: current_facility,
        user: current_user,
        recorded_at: second_follow_up_date)
    end

    describe ".follow_ups" do
      context "by day" do
        it "groups follow ups by day" do
          expect(Patient
                   .follow_ups_by_period(:day)
                   .count).to eq({first_follow_up_date => 2,
                                  second_follow_up_date => 1})
        end

        it "can be grouped by facility and day" do
          expect(Patient
                   .follow_ups_by_period(:day)
                   .group("encounters.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 2,
                                  [first_follow_up_date, follow_up_facility.id] => 1,
                                  [second_follow_up_date, current_facility.id] => 1,
                                  [second_follow_up_date, follow_up_facility.id] => 0})
        end

        it "can be filtered by region" do
          expect(Patient
                   .follow_ups_by_period(:day, at_region: current_facility)
                   .group("encounters.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 2,
                                  [second_follow_up_date, current_facility.id] => 1})
        end

        it "counts encounters created today regardless of reporting timezone" do
          with_reporting_time_zone do
            Timecop.freeze("May 1st 2021 12:00") do
              create(:blood_pressure,
                :with_encounter,
                patient: hypertensive_patient,
                facility: current_facility,
                user: current_user,
                recorded_at: Time.current)

              expect(Patient.follow_ups_by_period(:day, current: true, last: 30).count).to include({Date.today => 1})
            end
          end
        end
      end

      context "by month" do
        it "can be filtered by facility" do
          expect(Patient
                   .follow_ups_by_period(:month, at_region: current_facility)
                   .group("encounters.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 2})
        end
      end
    end

    describe ".diabetes_follow_ups" do
      context "by day" do
        it "groups follow ups by day" do
          expect(Patient
                   .diabetes_follow_ups_by_period(:day)
                   .count).to eq({first_follow_up_date => 1})
        end

        it "can be grouped by facility and day" do
          expect(Patient
                   .diabetes_follow_ups_by_period(:day)
                   .group("blood_sugars.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1})
        end
      end

      context "by month" do
        it "groups follow ups by month" do
          expect(Patient
                   .diabetes_follow_ups_by_period(:month)
                   .count).to eq({first_follow_up_date => 1})
        end

        it "can be grouped by facility and month" do
          expect(Patient
                   .diabetes_follow_ups_by_period(:month)
                   .group("blood_sugars.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1})
        end
      end
    end

    describe ".hypertension_follow_ups" do
      context "by day" do
        it "groups follow ups by day" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:day)
                   .count).to eq({first_follow_up_date => 1,
                                  second_follow_up_date => 1})
        end

        it "can be grouped by facility and day" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:day)
                   .group("blood_pressures.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                  [first_follow_up_date, follow_up_facility.id] => 1,
                                  [second_follow_up_date, current_facility.id] => 1,
                                  [second_follow_up_date, follow_up_facility.id] => 0})
        end

        it "can be filtered by region" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:day, at_region: current_facility)
                   .group("blood_pressures.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                  [second_follow_up_date, current_facility.id] => 1})
        end
      end

      context "by month" do
        it "groups follow ups by month" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:month)
                   .count).to eq({first_follow_up_date => 1})
        end

        it "can be grouped by facility and month" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:month)
                   .group("blood_pressures.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1,
                                  [first_follow_up_date, follow_up_facility.id] => 1})
        end

        it "can be filtered by region" do
          expect(Patient
                   .hypertension_follow_ups_by_period(:month, at_region: current_facility)
                   .group("blood_pressures.facility_id")
                   .count).to eq({[first_follow_up_date, current_facility.id] => 1})
        end
      end
    end
  end
end
