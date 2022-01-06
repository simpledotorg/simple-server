# frozen_string_literal: true

module Admin::UserHelper
  def facility_search_options
    current_admin.accessible_facilities(:manage) \
      .sort_by { |facility| facility.name.sub(/^Dr(.?)(\s*)/, "") } \
      .collect { |facility| [facility.label_with_district, facility.id] }
  end
end
