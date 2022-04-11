class PopulateFacilityShortNames < ActiveRecord::Migration[5.2]
  def up
    Facility.with_discarded.update_all("short_name = left(name, 30)")
  end

  def down
    Facility.with_discarded.update_all("short_name = NULL")
  end
end
