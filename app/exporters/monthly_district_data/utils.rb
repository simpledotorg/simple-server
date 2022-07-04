module MonthlyDistrictData::Utils
  def localized_district
    I18n.t("region_type.district")
  end

  def localized_block
    I18n.t("region_type.block")
  end

  def localized_facility
    I18n.t("region_type.facility")
  end

  def month_headers
    months.map { |month| month.value.strftime("%b-%Y") }
  end
end
