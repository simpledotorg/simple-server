module Notifiable
  def schedule_today_or_tomorrow(start, finish)
    now = DateTime
      .now
      .in_time_zone(Rails.application.config.country[:time_zone])

    if now_within_time_window?(now, start, finish)
      now
    elsif now.hour <= start
      now.change(hour: start)
    else
      now.change(hour: start) + 1.day
    end
  end

  def now_within_time_window?(now, start, finish)
    now.hour.between?(start, finish)
  end
end
