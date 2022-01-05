class UpdatePrescriptions < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_prescriptions, version: 2, revert_to_version: 1, materialized: true
  end
end
