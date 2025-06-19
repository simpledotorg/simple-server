class DrRai::ActionPlan < ApplicationRecord
  belongs_to :dr_rai_indicator
  belongs_to :dr_rai_target
  belongs_to :region
end
