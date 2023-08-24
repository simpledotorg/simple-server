require "rails_helper"

describe EthiopiaDhis2Exporter do
  before(:each) do
    Flipper.enable(:dhis2_export)
  end

  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/sandbox.yml"
    Rails.application.config.country = CountryConfig.for(:BD)
  end

  after do
    Rails.application.config.country = CountryConfig.for(ENV.fetch("DEFAULT_COUNTRY"))
  end

  describe ".export" do
    let(:facility) { build_stubbed(:facility, :dhis2) }
    it "exports the number of cumulative assigned patients" do
      create(:patient, assigned_facility: facility)
    end

    it "exports the cumulative assigned patients excluding new registrations" do
    end

    it "exports the cumulative registered patients" do
    end

    it "exports the number of dead patients" do
    end

    it "exports the number of monthly registered patients" do
    end
    it "exports the number of lost to follow up" do
    end
    it "exports the number of missed visits" do
    end
    it "exports the number of controlled patients" do
    end
    it "exports the number of uncontrolled patients" do
    end
    it "exports the number of controlled patients 6 months adjusted" do
    end
    it "exports the number of uncontrolled patients 6 months adjusted" do
    end
    it "exports the number of dead patients 6 months adjusted" do
    end
    it "exports the number of lost to follow up 6 months adjusted" do
    end
    it "exports the number of transferred out 6 months adjusted" do
    end
    it "exports the number of not evaludated 6 months adjusted" do
    end
  end
end
