module ApplicationHelper
  DEFAULT_PROGRAM_INCEPTION_DATE = Time.new(2018, 01, 01)

  def bootstrap_class_for_flash(flash_type)
    case flash_type
    when 'success'
      'alert-success'
    when 'error'
      'alert-danger'
    when 'alert'
      'alert-warning'
    when 'notice'
      'alert-primary'
    else
      flash_type.to_s
    end
  end

  def rounded_time_ago_in_words(date)
    if date == Date.today
      "Today"
    elsif date == Date.yesterday
      "Yesterday"
    elsif date <= 1.year.ago
      "on #{date.strftime("%d/%m/%Y")}".html_safe
    else
      "#{time_ago_in_words(date)} ago".html_safe
    end
  end

  def handle_impossible_registration_date(date, format: "%d-%b-%Y")
    program_inception_date = ENV['PROGRAM_INCEPTION_DATE'] ? ENV['PROGRAM_INCEPTION_DATE'].to_time : DEFAULT_PROGRAM_INCEPTION_DATE
    if date < program_inception_date # Date of inception of program
      'Unclear'
    else
      date.strftime(format)
    end
  end

  def show_last_interaction_date_and_result(patient)
    return if patient.appointments.count < 2

    last_appointment = patient.appointments.order(scheduled_date: :desc).second
    return if last_appointment.status == 'scheduled'

    last_appointment_date = last_appointment.created_at.strftime("%d-%b-%Y")
    interaction_result = "Last interaction: " + last_appointment_date

    if last_appointment.agreed_to_visit.present?
      interaction_result += ' - Agreed to visit'
    elsif last_appointment.remind_on.present?
      interaction_result += ' - Remind to call later'
    elsif last_appointment.status == Appointment.statuses[:visited]
      interaction_result += " - Visited"
    end

    interaction_result
  end
end

