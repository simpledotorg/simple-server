module Api::Current::PrioritisableByFacility
  extend ActiveSupport::Concern
  included do
    def current_facility_records
      model_name
        .where(facility: current_facility)
        .updated_on_server_since(current_facility_processed_since, limit)
    end

    def other_facility_records
      other_facilities_limit = limit - current_facility_records.count
      model_name
        .where(facility: current_user.facilities_in_group.where.not(id: current_facility.id))
        .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
    end
  end
end
