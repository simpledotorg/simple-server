class FacilitiesTeleconsultationMedicalOfficers < ActiveRecord::Migration[5.2]
  def change
    create_join_table :facilities,
      :users,
      column_options: {type: :uuid},
      table_name: "facilities_teleconsultation_medical_officers" do |t|
      t.index [:facility_id, :user_id], name: :index_facilities_teleconsult_mos_on_facility_id_and_user_id
    end
  end
end
