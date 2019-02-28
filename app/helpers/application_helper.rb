module ApplicationHelper
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
end
