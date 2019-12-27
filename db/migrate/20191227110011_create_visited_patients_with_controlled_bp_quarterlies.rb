class CreateVisitedPatientsWithControlledBpQuarterlies < ActiveRecord::Migration[5.1]
  def change
    create_view :visited_patients_with_controlled_bp_quarterlies, materialized: true
  end
end
