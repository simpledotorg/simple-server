class ChangeBloodSugarValueToNumericType < ActiveRecord::Migration[5.1]
  def up
    change_column :blood_sugars, :blood_sugar_value, :numeric
  end

  def down
    change_column :blood_sugars, :blood_sugar_value, :integer
  end
end
