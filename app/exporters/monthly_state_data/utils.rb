module MonthlyStateData::Utils
  def localized_state
    I18n.t("region_type.state")
  end

  def localized_district
    I18n.t("region_type.district")
  end

  def month_headers
    months.map { |month| month.value.strftime("%b-%Y") }
  end
end
