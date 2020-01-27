class MyFacilities::RegistrationsQuery
  include QuarterHelper

  NO_OF_QUARTERS = 3
  NO_OF_MONTHS = 3
  NO_OF_DAYS = 3

  def initialize(period: :quarterly,
                 facilities: Facility.all)
    @facilities = facilities
    @period = period
  end

  def registrations
    case @period
    when :quarterly
      quarterly_registrations
    when :monthly
      monthly_registrations
    when :daily
      daily_registrations
    end
  end


  def quarterly_registrations
    query_string = last_n_quarters(NO_OF_QUARTERS).map { |quarter| "('#{quarter.first}', '#{quarter.second}')" }.join(',')

    PatientRegistrationsPerDayPerFacility
      .where(facility: @facilities)
      .where("(year, quarter) IN (#{query_string})")
  end
end
