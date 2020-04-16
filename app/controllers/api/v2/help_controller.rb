class Api::V2::HelpController < Api::V3::HelpController
  include Api::V2::LogApiUsageByUsers
end
