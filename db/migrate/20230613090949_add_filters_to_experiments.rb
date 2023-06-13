class AddFiltersToExperiments < ActiveRecord::Migration[6.1]
  def change
    add_column :experiments, :filters, :json, default: {}
  end
end
