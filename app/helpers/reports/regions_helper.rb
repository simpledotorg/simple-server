module Reports::RegionsHelper
  def sum_registration_counts(repository, slug:, user_id:, diagnosis: :hypertension)
    repository.monthly_registrations_by_user(diagnosis: diagnosis).dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def sum_bp_measures(repository, slug:, user_id:)
    repository.bp_measures_by_user.dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def sum_blood_sugar_measures(repository, slug:, user_id:)
    repository.bp_measures_by_user.dig(slug)
      .map { |period, user_counts| user_counts.dig(user_id) }
      .flatten.compact.sum
  end

  def sum_overdue_calls(repository, slug:, user_id:)
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
end
