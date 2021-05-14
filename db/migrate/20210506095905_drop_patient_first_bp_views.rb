class DropPatientFirstBpViews < ActiveRecord::Migration[5.2]
  def change
    drop_view :patient_first_bp_views
  end
end
