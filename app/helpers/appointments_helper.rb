module AppointmentsHelper
  def blood_pressure_recorded_date(date)
    if date == Date.today
      "Today"
    elsif date == Date.yesterday
      "Yesterday"
    elsif date <= 1.year.ago
      date.strftime("%d/%m/%Y")
    else
      "#{(Date.today - date).to_i} days ago".html_safe
    end
  end
end
