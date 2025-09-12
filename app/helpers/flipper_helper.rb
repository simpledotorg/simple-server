module FlipperHelper
  def resolve_use_who_standard(use_who_standard)
    use_who_standard.nil? ? Flipper.enabled?(:diabetes_who_standard_indicator) : use_who_standard
  end

  def all_district_overview_enabled?
    Flipper.enabled?(:all_district_overview) && params[:facility_group] == "all-districts"
  end
end
