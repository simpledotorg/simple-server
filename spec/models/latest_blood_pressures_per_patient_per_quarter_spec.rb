require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerQuarter, type: :model do
  def refresh_views
    LatestBloodPressuresPerPatientPerMonth.refresh
    described_class.refresh
  end

  describe "Associations" do
    it { should belong_to(:patient) }
  end
end
