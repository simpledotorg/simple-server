module Reports::RegionsHelper
  def reports_region_facility_details_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_details_path(facility, options)
  end

  def reports_region_facility_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_path(facility, options)
  end

  def reports_region_district_path(district, options = {})
    options.with_defaults! report_scope: "district"
    reports_region_path(district, options)
  end

  def sum_registration_counts(repository, *keys)
    slug, user_id = keys
    repository.monthly_registrations_by_user.dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def sum_bp_measures(repository, *keys)
    slug, user_id = keys
    repository.bp_measures_by_user.dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def sum_overdue_calls(repository, *keys)
    slug, user_id = keys
    repository.overdue_calls_by_user.dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def percentage_or_na(value, options)
    return "N/A" if value.blank?
    number_to_percentage(value, options)
  end

  def cohort_report_type(period)
    "#{period.type.to_s.humanize}ly report"
  end

  def follow_ups_definition
    if current_admin.feature_enabled?(:follow_ups_v2)
      :follow_up_patients_copy_v2
    else
      :follow_up_patients_copy
    end
  end
end
