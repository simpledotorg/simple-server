class PatientBreakdownService
  CACHE_VERSION = 1

  def self.call(*args)
    new(*args).call
  end

  def initialize(region:, period: Period.month(Time.current))
    @region = region
    @period = period
    @facilities = region.facilities
  end

  attr_reader :region
  attr_reader :facilities

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) {
      breakdown_date = @period.start_date
      patients = Patient.with_hypertension.where(assigned_facility: facilities)

      {
        dead_patients: patients.status_dead.count,
        ltfu_patients: patients.excluding_dead.ltfu_as_of(breakdown_date).count,
        not_ltfu_patients: patients.excluding_dead.not_ltfu_as_of(breakdown_date).count,
        ltfu_transferred_patients: patients.ltfu_as_of(breakdown_date).status_migrated.count,
        not_ltfu_transferred_patients: patients.not_ltfu_as_of(breakdown_date).status_migrated.count,
        total_patients: patients.count
      }
    }
  end

  def cache_key
    "#{self.class}/#{region.cache_key}"
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
