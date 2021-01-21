module TimeAndDateExtensions
  def to_period
    Period.month(to_date)
  end
end

Date.include TimeAndDateExtensions
Time.include TimeAndDateExtensions
