require "rails_helper"

describe Experiment, type: :model do
  subject(:experiment) { create(:experiment) }

  describe "associations" do
    it { should have_many(:appointment_reminders) }
  end

end