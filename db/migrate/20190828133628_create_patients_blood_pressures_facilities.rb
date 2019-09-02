class CreatePatientsBloodPressuresFacilities < ActiveRecord::Migration[5.1]
  def change
    create_view :patients_blood_pressures_facilities
  end
end
