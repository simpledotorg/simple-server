class MakePopulationNullable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :estimated_populations, :population, true
    change_column_default :estimated_populations, :population, to: nil
  end
end
