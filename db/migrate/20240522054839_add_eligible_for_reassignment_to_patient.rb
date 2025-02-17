class AddEligibleForReassignmentToPatient < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :eligible_for_reassignment, :text, default: "unknown", null: false
  end
end
