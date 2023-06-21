class ImportFacilitiesJob < ApplicationJob
  def perform(facilities:, business_identifiers:)
    import_facilities = []
    import_business_identifiers = []

    facilities.each do |facility|
      organization = Organization.find_by(name: facility[:organization_name])
      facility_group = FacilityGroup.find_by(name: facility[:facility_group_name], organization_id: organization.id)
      import_facility = Facility.new(facility.merge!(facility_group_id: facility_group.id))
      import_facilities << import_facility
    end

    business_identifiers.each do |identifier|
      import_business_identifiers << FacilityBusinessIdentifier.new(identifier)
    end

    ActiveRecord::Base.transaction do
      Facility.import!(import_facilities, validate: true)
      # import! can't run callbacks, so we manually ensure that we create regions
      import_facilities.each(&:make_region)

      FacilityBusinessIdentifier.import!(import_business_identifiers, validate: true)
    end
  end
end
