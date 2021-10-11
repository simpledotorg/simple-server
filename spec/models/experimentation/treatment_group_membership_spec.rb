require "rails_helper"

RSpec.describe Experimentation::TreatmentGroupMembership, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_group) }
    it { should belong_to(:patient) }

    describe "validations" do
      it "should validate that a patient is allowed only in only one active experiment at a time" do
        experiment_1 = create(:experiment, state: :running, experiment_type: "current_patients")
        experiment_2 = create(:experiment, state: :running, experiment_type: "stale_patients")
        treatment_group_1 = create(:treatment_group, experiment: experiment_1)
        treatment_group_2 = create(:treatment_group, experiment: experiment_2)

        patient = create(:patient, age: 18)

        treatment_group_1.patients << patient
        treatment_group_2_membership = build(:treatment_group_membership, patient: patient, treatment_group: treatment_group_2)

        treatment_group_2_membership.validate
        expect(treatment_group_2_membership.errors).to be_present
      end
    end
  end
end
