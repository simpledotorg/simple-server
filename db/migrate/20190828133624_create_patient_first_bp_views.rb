class CreatePatientFirstBpViews < ActiveRecord::Migration[5.1]
  def change
    create_view :patient_first_bp_views
  end
end
