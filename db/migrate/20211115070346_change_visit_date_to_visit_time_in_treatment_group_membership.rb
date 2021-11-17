class ChangeVisitDateToVisitTimeInTreatmentGroupMembership < ActiveRecord::Migration[5.2]
  def change
    change_column :treatment_group_memberships, :visit_date, :datetime
    rename_column :treatment_group_memberships, :visit_date, :visited_at
  end
end
