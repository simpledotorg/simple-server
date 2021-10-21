require "rails_helper"

RSpec.describe Experimentation::NotificationsExperiment, type: :model do
  describe ".candidate_patients" do
    it "doesn't include patients from a running experiment" do
      experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      treatment_group = create(:treatment_group, experiment: experiment)

      patient = create(:patient, age: 18)
      not_enrolled_patient = create(:patient, age: 18)

      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
      expect(described_class.candidate_patients).to include(not_enrolled_patient)
    end

    it "includes patients from experiments that ended before 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).to include(patient)
    end

    it "doesn't include patients from experiments that ended within 14 days" do
      experiment = create(:experiment, start_time: 30.days.ago, end_time: 10.days.ago)
      treatment_group = create(:treatment_group, experiment: experiment)
      patient = create(:patient, age: 18)
      treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients are in a future experiment" do
      future_experiment = create(:experiment, start_time: 10.days.from_now, end_time: 20.days.from_now)
      future_treatment_group = create(:treatment_group, experiment: future_experiment)

      patient = create(:patient, age: 18)

      future_treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients who were once in a completed experiment but are now in a running experiment" do
      running_experiment = create(:experiment, start_time: 1.day.ago, end_time: 1.day.from_now)
      old_experiment = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      running_treatment_group = create(:treatment_group, experiment: running_experiment)
      old_treatment_group = create(:treatment_group, experiment: old_experiment)

      patient = create(:patient, age: 18)

      old_treatment_group.enroll(patient)
      running_treatment_group.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "doesn't include patients twice if they were in multiple experiments that ended" do
      experiment_1 = create(:experiment, start_time: 10.days.ago, end_time: 5.days.ago)
      experiment_2 = create(:experiment, start_time: 30.days.ago, end_time: 15.days.ago)
      treatment_group_1 = create(:treatment_group, experiment: experiment_1)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)

      patient = create(:patient, age: 18)

      treatment_group_1.enroll(patient)
      treatment_group_2.enroll(patient)

      expect(described_class.candidate_patients).not_to include(patient)
    end

    it "excludes any patients who have multiple scheduled appointments" do
      excluded_patient = create(:patient, age: 18)
      create_list(:appointment, 2, patient: excluded_patient, status: :scheduled)

      included_patient = create(:patient, age: 18)
      create(:appointment, patient: included_patient, status: :scheduled)

      expect(described_class.candidate_patients).not_to include(excluded_patient)
      expect(described_class.candidate_patients).to include(included_patient)
    end
  end

end
