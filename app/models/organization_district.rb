class OrganizationDistrict < Struct.new(:district_name, :organization)
  include QuarterHelper

  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def cohort_analytics(period: :month, periods: 6)
    patients =
      Patient
        .joins(:registration_facility)
        .where(facilities: { id: facilities })

    query = CohortAnalyticsQuery.new(patients)
    results = {}

    (0..(periods - 1)).each do |periods_back|
      if period = :month
        cohort_start = (Time.now - periods_back.months).beginning_of_month
        cohort_end   = cohort_start.end_of_month
        report_start = (cohort_start + 1.month).beginning_of_month
        report_end   = (cohort_end + 1.month).end_of_month
      else
        cohort_start = (Time.now - periods_back.quarters).beginning_of_quarter
        cohort_end   = cohort_end.end_of_quarter
        report_start = (cohort_start + 3.months).beginning_of_quarter
        report_end   = (cohort_end + 3.months).end_of_quarter
      end

      results[periods_back] = query.patient_counts(cohort_start, cohort_end, report_start, report_end)
    end

    results
  end

  def dashboard_analytics(time_period: :month)
    query = DistrictAnalyticsQuery.new(district_name,
                                       organization,
                                       time_period)
    results = [
      query.registered_patients_by_period,
      query.total_registered_patients,
      query.follow_up_patients_by_period,
      query.total_calls_made_by_period
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end
end
