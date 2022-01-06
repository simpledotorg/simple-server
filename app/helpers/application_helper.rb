# frozen_string_literal: true

module ApplicationHelper
  DEFAULT_PROGRAM_INCEPTION_DATE = Time.new(2018, 0o1, 0o1)
  STANDARD_DATE_DISPLAY_FORMAT = "%d-%^b-%Y"

  def page_title
    title = content_for?(:title) ? content_for(:title) : I18n.t("admin.dashboard_title")
    [env_prefix, title].compact.join(" ")
  end

  def bootstrap_class_for_flash(flash_type)
    case flash_type
    when "success"
      "alert-success"
    when "error"
      "alert-danger"
    when "alert"
      "alert-warning"
    when "notice"
      "alert-primary"
    else
      flash_type.to_s
    end
  end

  def display_date(date)
    date&.strftime(STANDARD_DATE_DISPLAY_FORMAT)
  end

  def rounded_time_ago_in_words(date)
    if date == Date.current
      "Today"
    elsif date == Date.yesterday
      "Yesterday"
    else
      "on #{display_date(date)}".html_safe
    end
  end

  # Calculate a percentage and then pass on the result to number_to_percentage.
  # Defaults to precision of 0.
  def compute_percentage(numerator, denominator, options = {})
    return "N/A" if denominator == 0
    options = options.with_defaults(precision: 0)
    quotient = numerator.to_f / denominator.to_f
    number_to_percentage(quotient * 100, options)
  end

  def handle_impossible_registration_date(date)
    program_inception_date =
      ENV["PROGRAM_INCEPTION_DATE"] ? ENV["PROGRAM_INCEPTION_DATE"].to_time : DEFAULT_PROGRAM_INCEPTION_DATE
    if date < program_inception_date # Date of inception of program
      "Unclear"
    else
      display_date(date)
    end
  end

  def show_last_interaction_date_and_result(patient)
    ordered_appointments = patient.appointments.sort_by(&:scheduled_date).reverse
    last_interaction = ordered_appointments.second

    return unless last_interaction.present?

    last_interaction_date = last_interaction.created_at.strftime(STANDARD_DATE_DISPLAY_FORMAT)
    interaction_result = "" + last_interaction_date

    if last_interaction.agreed_to_visit.present?
      interaction_result += " - Agreed to visit"
    elsif last_interaction.remind_on.present?
      interaction_result += " - Remind to call later"
    elsif last_interaction.status_visited?
      interaction_result += " - Visited facility"
    end

    interaction_result
  end
end
