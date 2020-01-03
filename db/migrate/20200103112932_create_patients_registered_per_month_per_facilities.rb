class CreatePatientsRegisteredPerMonthPerFacilities < ActiveRecord::Migration[5.1]
  def change
    create_view :patients_registered_per_month_per_facilities, materialized: true
  end
end
