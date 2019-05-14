class CachedLatestBloodPressure < BloodPressure
  self.table_name =  'cached_latest_blood_pressures'

  belongs_to :patient

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end
end
