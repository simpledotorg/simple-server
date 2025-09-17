module FlipperHelper  
  def resolve_use_who_standard(use_who_standard)
    use_who_standard.nil? ? Flipper.enabled?(:diabetes_who_standard_indicator) : use_who_standard
  end

  def all_district_overview_feature_enabled?
    Flipper.enabled?(:all_district_overview, current_admin)
  end

  def all_district_overview_enabled?
    all_district_overview_feature_enabled? && params[:facility_group] == "all-districts"
  end

  def access_all_districts_overview?
    all_district_overview_feature_enabled? && accessible_organization_facilities.present?
  end
end
