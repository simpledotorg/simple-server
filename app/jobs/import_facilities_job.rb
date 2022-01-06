# frozen_string_literal: true

class ImportFacilitiesJob < ApplicationJob
  def perform(facilities)
    import_facilities = []

    facilities.each do |facility|
      organization = Organization.find_by(name: facility[:organization_name])
      facility_group = FacilityGroup.find_by(name: facility[:facility_group_name], organization_id: organization.id)
      import_facility = Facility.new(facility.merge!(facility_group_id: facility_group.id))
      import_facilities << import_facility
    end

    ActiveRecord::Base.transaction do
      Facility.import!(import_facilities, validate: true)
      # import! can't run callbacks, so we manually ensure that we create regions
      import_facilities.each(&:make_region)
    end
  end
end
