module SetForEndOfMonth
  def set_for_end_of_month
    # Defaults to current month if it's the last week of the month.
    @show_current_month = ((Date.current.end_of_month - Date.current).to_i <= 7)

    @for_end_of_month ||= if params[:for_end_of_month]
      Time.zone.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    elsif @show_current_month
      Time.current.end_of_month
    else
      Time.current.prev_month.end_of_month
    end
  end
end
