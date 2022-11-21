class AddIndexOnCallResultFacilityId < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :call_results, [:facility_id], name: :index_call_results_on_facility_id, algorithm: :concurrently
  end
end
