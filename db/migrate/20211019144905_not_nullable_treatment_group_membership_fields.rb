class NotNullableTreatmentGroupMembershipFields < ActiveRecord::Migration[5.2]
  def change
    change_column_null :treatment_group_memberships, :experiment_id, false
    change_column_null :treatment_group_memberships, :experiment_name, false
    change_column_null :treatment_group_memberships, :treatment_group_name, false
  end
end
