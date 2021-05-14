class DropPatientsBloodPressuresFacilities < ActiveRecord::Migration[5.2]
  def change
    drop_view :patients_blood_pressures_facilities
  end
end
