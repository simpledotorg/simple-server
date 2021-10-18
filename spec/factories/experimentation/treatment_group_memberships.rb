FactoryBot.define do
  factory :treatment_group_membership, class: Experimentation::TreatmentGroupMembership do
    association :patient, factory: :patient
    association :treatment_group, factory: :treatment_group
  end
end
