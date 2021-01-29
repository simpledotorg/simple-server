class RegionsSearchController < AdminController
  include ActiveSupport::Benchmarkable
  delegate :cache, to: Rails
  CACHE_VERSION = "V3"

  def show
    regions = []
    benchmark("retrieving all accessible regions for search") do
      authorize do
        regions.concat current_admin.user_access.accessible_state_regions(:view_reports)
        regions.concat current_admin.user_access.accessible_district_regions(:view_reports)
        regions.concat current_admin.user_access.accessible_block_regions(:view_reports)
        regions.concat current_admin.user_access.accessible_facility_regions(:view_reports)
      end
    end
    @query = params.permit(:query)[:query] || ""
    regex = /.*#{Regexp.escape(@query)}.*/i
    results = search(regions, regex)
    json = results.sort_by(&:name).map { |region|
      {
        ancestors: region.cached_ancestors.reject { |r| r.region_type.in?(["root", "organization"]) }.map { |r| r.name }.join(" > "),
        id: region.id,
        name: region.name,
        slug: region.slug,
        link: reports_region_url(region, report_scope: region.region_type)
      }
    }
    render json: json
  end

  private

  def search(regions, regex)
    regions.select { |region| regex.match?(region.name) }
  end
end
