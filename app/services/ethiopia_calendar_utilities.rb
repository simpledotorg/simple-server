module EthiopiaCalendarUtilities
  def self.ethiopian_to_gregorian(e_year, e_month, e_days)
    year = e_year + 8
    leap_correction = (e_year + 1) % 4 == 1 ? 22 : 23
    days_offset = e_month * 30 - 120 + e_days - leap_correction

    Date.new(year, 1, 1) + days_offset.days
  end
end
