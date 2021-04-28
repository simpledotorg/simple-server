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
      regions = [facility_1.region, facility_2.region]
      periods = (3.months.ago.to_period..1.month.ago.to_period)

      patient = create(:patient, :hypertension, recorded_at: 10.months.ago)

      create(:blood_pressure, :with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient)
      create(:blood_pressure, :with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient)

      repo = Reports::Repository.new(regions, periods: periods)
      repo_result = repo.hypertension_follow_ups
      pp repo_result

      expect(facility_1.hypertension_follow_ups_by_period(:month, last: 4).count[1.month.ago.beginning_of_month.to_date]).to eq 0
      expect(facility_2.hypertension_follow_ups_by_period(:month, last: 4).count[3.months.ago.beginning_of_month.to_date]).to eq 0

      expect(facility_1.hypertension_follow_ups_by_period(:month, last: 4).count[3.month.ago.beginning_of_month.to_date]).to eq 1
      expect(facility_2.hypertension_follow_ups_by_period(:month, last: 4).count[1.months.ago.beginning_of_month.to_date]).to eq 1
    end
  end

  context "follow ups" do
    let(:reg_date) { Date.new(2018, 1, 1) }
    let(:current_user) { create(:user) }
    let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
    let(:follow_up_facility) { create(:facility, facility_group: current_user.facility.facility_group) }
    let(:hypertensive_patient) { create(:patient, registration_facility: current_facility, recorded_at: reg_date) }
    let(:diabetic_patient) {
      create(:patient,
        :diabetes,
        registration_facility: current_facility,
        recorded_at: reg_date)
    }
    let(:first_follow_up_date) { reg_date + 1.month }
    let(:second_follow_up_date) { first_follow_up_date + 1.day }

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
      end

      context "by month" do
        it "can be filtered by facility" do
          query = FollowUpsQuery.new(current_facility, :month)
          expected = {
            first_follow_up_date.to_period => 2
          }
          expect(query.encounters).to eq(expected)
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
