class Dashboard::Header::BreadcrumbsComponent < ApplicationComponent
  attr_reader :region, :current_admin

  def initialize(region:, current_admin:)
    @region = region
    @current_admin = current_admin
  end

  def ancestors
    region.ancestors.where(region_type: %w[state district block facility]).order(:path)
  end

  def ancestor_link(ancestor)
    link_to_if(accessible_region?(ancestor, :view_reports),
      ancestor.name,
      reports_region_path(ancestor.slug, report_scope: ancestor.region_type))
  end

  def accessible_region?(region, action)
    return false unless region.reportable_region?
    current_admin.region_access(memoized: true).accessible_region?(region, action)
  end
end
