class RegionsSearchController < AdminController
  delegate :cache, to: Rails

  def show
    accessible_facility_regions = authorize { current_admin.accessible_facility_regions(:view_reports) }
    cache_key = "#{current_admin.cache_key}/regions/index"
    cache_version = "#{accessible_facility_regions.cache_key} / v2"
    @accessible_regions = cache.fetch(cache_key, version: cache_version, expires_in: 7.days) {
      accessible_facility_regions.each_with_object({}) { |facility, result|
        ancestors = Hash[facility.cached_ancestors.map { |facility| [facility.region_type, facility] }]
        org, state, district, block = ancestors.values_at("organization", "state", "district", "block")
        result[org] ||= {}
        result[org][state] ||= {}
        result[org][state][district] ||= {}
        result[org][state][district][block] ||= []
        result[org][state][district][block] << facility
      }
    }
    @query = params.permit(:query)[:query] || ""
    regex = /.*#{Regexp.escape(@query)}.*/i
    results = search(@accessible_regions, regex)
    json = results.sort_by(&:name).map { |region|
      {
        ancestors: region.cached_ancestors.where.not(region_type: "root").order(:path).map { |a| a.name }.join(" > "),
        id: region.id,
        name: region.name,
        slug: region.slug,
        link: reports_region_url(region, report_scope: region.region_type)
      }
    }
    render json: json
  end

  private

  def search(hash, regex)
    results = []
    hash.each_pair do |parent, children|
      results << parent if regex.match?(parent.name)

      if children.is_a?(Hash)
        results.concat search(children, regex)
      else
        results.concat children.find_all { |r| regex.match?(r.name) }
      end
    end
    results.flatten
  end
end
