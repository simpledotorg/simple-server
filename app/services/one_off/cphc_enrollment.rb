module OneOff::CphcEnrollment
  FACILITY_TYPE_ID = {
    "SUBCENTER" => 3100,
    "PHC" => 3200,
    "CHC" => 3300,
    "DH" => 3400,
    "TERTIARY" => 3500
  }

  CPHC_MIGRATION_WINDOW_START = "cphc_migration_window_start_hours"
  CPHC_MIGRATION_WINDOW_END = "cphc_migration_window_end_hours"

  def self.next_migration_time(at_time)
    window = migration_window

    if at_time < window[:start_time]
      window[:start_time]
    elsif at_time > window[:start_time] && at_time < window[:end_time]
      at_time
    else
      window[:start_time] + 1.day
    end
  end

  def self.in_migration_window?(timestamp)
    window = migration_window
    timestamp > window[:start_time] && timestamp < window[:end_time]
  end

  def self.migration_window
    cphc_window_start_time = Configuration.find_by!(name: CPHC_MIGRATION_WINDOW_START).value.to_i
    cphc_window_end_time = Configuration.find_by!(name: CPHC_MIGRATION_WINDOW_END).value.to_i
    current_time = Time.now

    start_time = current_time.change(
      hour: cphc_window_start_time / 100,
      min: cphc_window_start_time % 100
    )
    end_time = current_time.change(
      hour: cphc_window_end_time / 100,
      min: cphc_window_end_time % 100
    )
    end_time += 1.day if end_time < start_time

    {start_time: start_time, end_time: end_time}
  end
end
