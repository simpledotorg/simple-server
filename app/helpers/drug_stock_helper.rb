module DrugStockHelper
  def drug_stock_region_label(region)
    if region.district_region?
      "#{region.localized_region_type.capitalize} warehouse"
    else
      region.localized_region_type.capitalize
    end
  end
end
