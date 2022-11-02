class CphcCreateUserJob
  include Sidekiq::Worker

  sidekiq_options queue: :cphc_migration

  def perform(facility_id)
    facility = Facility.find(facility_id)

    # TODO: How do we show the error to the user
    OneOff::CphcEnrollment::AuthManager.new(facility).create_user
  end
end
