module Api::V1::ApiControllerOverrides
  extend ActiveSupport::Concern
  included do
    def current_facility
      nil
    end

    def validate_facility
      true
    end

    def validate_current_facility_belongs_to_users_facility_group
      true
    end
  end
end
