class ImportFacilitiesJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(facilities)

    import_facilities = []
    facilities.each do |facility|
      organization = Organization.find_by(name: facility[:organization_name])
      facility_group = FacilityGroup.find_by(name: facility[:facility_group_name],
                                             organization_id: organization.id)
      import_facility = Facility.new(facility.merge!(facility_group_id: facility_group.id))
      import_facilities << import_facility
    end
    Facility.import!(import_facilities, validate: true)
  end
end
