class OrganizationDistrict < Struct.new(:district_name, :organization)
  include QuarterHelper

  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def cohort_analytics
    patients =
      Patient
        .joins(:registration_facility)
        .where(facilities: { id: facilities })

    query = CohortAnalyticsQuery.new(patients)
    results = {}

    (0..2).each do |quarters_back|
      date = (Date.today - (quarters_back * 3).months).beginning_of_quarter
      results[date] = query.patient_counts(year: date.year, quarter: quarter(date))
    end

    results
  end

  def dashboard_analytics
    query = DistrictAnalyticsQuery.new(district_name, organization)
    results = [
      query.registered_patients_by_month,
      query.total_registered_patients,
      query.follow_up_patients_by_month,
      query.total_calls_made_by_month
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end
end
