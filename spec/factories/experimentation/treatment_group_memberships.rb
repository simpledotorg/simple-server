FactoryBot.define do
  factory :treatment_group_membership, class: Experimentation::TreatmentGroupMembership do
    association :patient, factory: :patient
    association :treatment_group, factory: :treatment_group

    experiment { treatment_group.experiment }
    experiment_name { experiment.name }
    treatment_group_name { treatment_group.description }
  end
end
