class CreatePatientLineLists < ActiveRecord::Migration[5.1]
  def change
    create_view :patient_line_lists
  end
end
