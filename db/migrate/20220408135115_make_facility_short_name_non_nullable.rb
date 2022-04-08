class MakeFacilityShortNameNonNullable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :facilities, :short_name, true
  end
end
