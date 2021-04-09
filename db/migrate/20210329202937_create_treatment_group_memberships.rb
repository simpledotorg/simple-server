class CreateTreatmentGroupMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :treatment_group_memberships do |t|
      t.references :treatment_group, type: :uuid, null: false, foreign_key: true
      t.references :patient, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
