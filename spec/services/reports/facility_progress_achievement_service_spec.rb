require "rails_helper"

RSpec.describe Reports::FacilityProgressAchievementService, type: :model do
  let(:current_user) { create(:user) }
  let(:current_facility) { create(:facility, facility_group: current_user.facility.facility_group) }

  context "trophies" do
    it "has both unlocked and the upcoming locked trophy" do
      # create follow ups
      patients = create_list(:patient, 3, :hypertension, registration_facility: current_facility, recorded_at: 6.months.ago)
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

      refresh_views
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
        total_counts = instance_double("Reports::FacilityStateDimension", monthly_follow_ups_htn_all: 5_000)
        achievements = described_class.new(current_facility)
        expect(achievements).to receive(:total_counts).and_return(total_counts)

        expected_output = {
          locked_trophy_value: 10_000,
          unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
        }

        expect(achievements.statistics[:trophies]).to eq(expected_output)
      end

      it "unlocks a milestone of 10_000 if follow_ups are between 5_000...10_000" do
        total_counts = instance_double("Reports::FacilityStateDimension", monthly_follow_ups_htn_all: 5_001)
        achievements = described_class.new(current_facility)
        expect(achievements).to receive(:total_counts).and_return(total_counts)

        expected_output = {
          locked_trophy_value: 10_000,
          unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
        }

        expect(achievements.statistics[:trophies]).to eq(expected_output)
      end

      it "unlocks milestones in increments of 10_000 after reaching 10_000" do
        total_counts = instance_double("Reports::FacilityStateDimension", monthly_follow_ups_htn_all: 10_000)
        achievements = described_class.new(current_facility)
        expect(achievements).to receive(:total_counts).and_return(total_counts)

        expected_output = {
          locked_trophy_value: 20_000,
          unlocked_trophy_values: [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000, 10_000]
        }

        expect(achievements.statistics[:trophies]).to eq(expected_output)
      end
    end
  end
end
