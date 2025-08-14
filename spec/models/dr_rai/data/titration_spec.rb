require "rails_helper"

RSpec.describe DrRai::Data::Titration, type: :model do
  context "data transformations" do
    # from
    # month_date, facility_name, follow_up_count, titrated_count, titration_rate
    # May 1 2025, Some Hospital, 120, 14, 11.67
    # to
    # {
    #   "Some Hospital": {
    #     <Period value: "Q2-2025">: {
    #       follow_up_count: 120,
    #       titrated_count: 14,
    #       titration_rate: 106,
    #     }
    #   }
    # }
    pending "transforms into dashboard format"
  end
end
