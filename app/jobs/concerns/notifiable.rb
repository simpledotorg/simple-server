module Notifiable
  def schedule_now_or_later(start, finish)
    now = DateTime.now.in_time_zone(ENV.fetch('DEFAULT_TIME_ZONE'))

    now_within_time_window?(now, start, finish) ?
      now :
      now.change(hour: @schedule_at_hour_of_day) + 1.day
  end

  def now_within_time_window?(now, start, finish)
    now.hour.between?(start, finish)
  end
end
