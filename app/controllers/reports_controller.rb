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
  end
end
