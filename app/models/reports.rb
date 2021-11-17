module Reports
  REGISTRATION_BUFFER_IN_MONTHS = 3
  MAX_MONTHS_OF_DATA = 24
  PERCENTAGE_PRECISION = 0

  # The default period we report on is the current month.
  def self.default_period
    Period.month(Time.current.in_time_zone(Period::REPORTING_TIME_ZONE))
  end

  def self.reporting_schema_v2?
    return RequestStore.store[:reporting_schema_v2] if RequestStore.store.key?(:reporting_schema_v2)
    true
  end

  def self.reporting_schema_v2=(value)
    RequestStore.store[:reporting_schema_v2] = value
  end
end
