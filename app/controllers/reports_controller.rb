class ReportsController < ApplicationController
  layout "reports"
  def index
    @controlled_patients = {
      "Jan 2017" => 323423,
      "Feb 2017" => 23423,
    }
    @registrations = {
      "Jan 2017" => 323423,
      "Feb 2017" => 23423,
    }
    @quarterly_registrations = {
      "Q2-2019" => {
        "visisted_and_controlled" => 324234,
        "visisted_and_uncontrolled" => 23423,
        "no_bp_measure" => 234234
      }


    }
  end
end
