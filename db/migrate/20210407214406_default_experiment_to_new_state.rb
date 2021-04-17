class DefaultExperimentToNewState < ActiveRecord::Migration[5.2]
  def change
    change_column_default :experiments, :state, from: nil, to: "new"
  end
end
