class AddTreatmentGroupMembershipConstraint < ActiveRecord::Migration[5.2]
  def up
    patients_in_multiple_experiments =
      Experimentation::TreatmentGroupMembership
        .group(:patient_id, :experiment_id)
        .having("count(*) > 1")
        .select(:patient_id)

    Experimentation::TreatmentGroupMembership
      .where(patient_id: patients_in_multiple_experiments)
      .destroy_all

    add_index :treatment_group_memberships, [:patient_id, :experiment_id], unique: true, name: "index_tgm_patient_id_and_experiment_id"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
