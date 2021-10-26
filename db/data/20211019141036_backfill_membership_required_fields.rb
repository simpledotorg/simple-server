class BackfillMembershipRequiredFields < ActiveRecord::Migration[5.2]
  def up
    Experimentation::TreatmentGroup.includes(:experiment).each do |group|
      Experimentation::TreatmentGroupMembership.where(treatment_group_id: group.id).update_all(
        treatment_group_name: group.description,
        experiment_name: group.experiment.name,
        experiment_id: group.experiment.id
      )
    end
  end

  def down
  end
end
