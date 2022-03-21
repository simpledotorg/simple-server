require "rails_helper"

RSpec.describe CountryConfig do
  describe "Messaging service" do
    it "has valid messaging channels in country config" do
      expect(CountryConfig::CONFIGS
               .values
               .pluck(:appointment_reminders_channel)
               .compact
               .all?(&:constantize)
      ).to eq true
    end
  end
end
