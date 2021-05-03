module SetForEndOfMonth
  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    elsif (Date.current.end_of_month - Date.current).to_i < 8
      Date.current.end_of_month
    else
      Date.current.prev_month.end_of_month
    end
  end
end
