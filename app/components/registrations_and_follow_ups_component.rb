# frozen_string_literal: true

class RegistrationsAndFollowUpsComponent < ViewComponent::Base
  include DashboardHelper
  attr_reader :region
  attr_reader :repository
  attr_reader :current_admin
  attr_reader :current_period
  attr_reader :range

  def initialize(region, current_admin:, repository:, current_period:)
    @region = region
    @repository = repository
    @range = repository.periods
    @current_admin = current_admin
    @current_period = current_period
  end

  def follow_ups_definition
    if current_admin.feature_enabled?(:follow_ups_v2)
      :follow_up_patients_copy_v2
    else
      :follow_up_patients_copy
    end
  end

  def reports_region_facility_details_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_details_path(facility, options)
  end

  def reports_region_facility_path(facility, options = {})
    options.with_defaults! report_scope: "facility"
    reports_region_path(facility, options)
  end

  def reports_region_district_path(district, options = {})
    options.with_defaults! report_scope: "district"
    reports_region_path(district, options)
  end

end
