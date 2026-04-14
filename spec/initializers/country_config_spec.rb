require "rails_helper"

RSpec.describe CountryConfig do
  describe "Messaging service" do
    it "has valid messaging channels in country config" do
      expect(
        CountryConfig::CONFIGS
          .values
          .pluck(:appointment_reminders_channel)
          .all?(&:constantize)
      ).to eq true
    end
  end

  describe ".supported_genders" do
    it "returns supported genders from the current country config" do
      test_genders = %w[male female]
      allow(CountryConfig).to receive(:current).and_return({supported_genders: test_genders})

      expect(CountryConfig.supported_genders).to eq(test_genders)
    end

    it "returns fallback genders when not configured" do
      allow(CountryConfig).to receive(:current).and_return({})

      expect(CountryConfig.supported_genders).to eq(%w[male female transgender])
    end
  end
end
