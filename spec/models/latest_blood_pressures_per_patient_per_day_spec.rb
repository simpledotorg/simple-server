require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerDay, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
  end
end
