class PatientBreakdownService
  CACHE_VERSION = 1

  def initialize(region:, period:)
    @region = region
    @facilities = region.facilities
    @period = period
  end

  attr_reader :region
  attr_reader :period
  attr_reader :facilities

  def self.call(*args)
    new(*args).call
  end

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) {
      patients = Patient.with_hypertension.where(assigned_facility: @facilities)

      {
        dead: patients.status_dead.count,
        ltfu_patients: patients.ltfu_as_of(period.to_date).count,
        not_ltfu_patients: patients.not_ltfu_as_of(period.to_date).count,
        ltfu_transferred_patients: patients.ltfu_as_of(period.to_date).status_migrated.count,
        not_ltfu_transferred_patients: patients.not_ltfu_as_of(period.to_date).status_migrated.count,
        total_patients: patients.count
      }
    }
  end

  def cache_key
    "#{self.class}/#{region.cache_key}/#{@period.type}"
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
