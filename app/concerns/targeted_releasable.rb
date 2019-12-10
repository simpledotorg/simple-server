module TargetedReleasable
  extend ActiveSupport::Concern

  included do
    def roll_out_for(total_size, percentage_config)
      desired_percentage = ENV[percentage_config].to_f
      (total_size * (desired_percentage.to_f / 100.0)).floor
    end
  end
end
