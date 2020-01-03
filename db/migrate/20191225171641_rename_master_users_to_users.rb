class RenameMasterUsersToUsers < ActiveRecord::Migration[5.1]
  def change
    drop_view :bp_drugs_views
    drop_view :bp_views
    drop_view :follow_up_views
    drop_view :overdue_views
    drop_view :patient_first_bp_views
    drop_view :patients_blood_pressures_facilities
    drop_view :users

    rename_table :master_users, :users
    create_view :bp_drugs_views
    create_view :bp_views
    create_view :follow_up_views
    create_view :overdue_views
    create_view :patient_first_bp_views
    create_view :patients_blood_pressures_facilities
  end
end
