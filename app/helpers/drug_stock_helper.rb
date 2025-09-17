module DrugStockHelper
  def drug_stock_region_label(region)
    if region.district_region?
      "#{region.localized_region_type.capitalize} warehouse"
    else
      region.localized_region_type.capitalize
    end
  end

  def filter_params
    params[:zone].present? || params[:size].present?
  end

  def accessible_organization_facilities
    if CountryConfig.current_country?("Bangladesh")
      Organization.joins(facility_groups: :facilities).where(facilities: {id: @accessible_facilities}).distinct.pluck(:slug).include?("nhf")
    else
      true
    end
  end

  def accessible_organization_districts
    if CountryConfig.current_country?("Bangladesh")
      @districts = FacilityGroup
        .includes(:facilities)
        .joins(:organization)
        .where(
          organization: {slug: "nhf"},
          id: @accessible_facilities.pluck(:facility_group_id).uniq
        )
        .order(:name)
    else
      FacilityGroup.where(id: @accessible_facilities.pluck(:facility_group_id).uniq).order(:name)
    end
  end
end
