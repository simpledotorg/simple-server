module TargetedReleasable
  extend ActiveSupport::Concern

  included do
    def facility_eligible?(facility_id, facility_ids_config)
      facility_ids = ENV.fetch(facility_ids_config).split(',')
      facility_ids.blank? ? true : facility_ids.include?(facility_id)
    end

    def roll_out_for(total_size, percentage_config)
      desired_percentage = ENV.fetch(percentage_config).to_f
      (total_size * (desired_percentage.to_f / 100.0)).floor
    end
  end
end
