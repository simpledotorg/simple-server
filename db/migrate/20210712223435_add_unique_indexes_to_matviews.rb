class AddUniqueIndexesToMatviews < ActiveRecord::Migration[5.2]
  def change
    add_index :reporting_patient_blood_pressures, [:month_date, :patient_id], unique: true, name: "patient_blood_pressures_patient_id_month_date"
    add_index :reporting_patient_visits, [:month_date, :patient_id], unique: true, name: "patient_visits_patient_id_month_date"
  end
end
