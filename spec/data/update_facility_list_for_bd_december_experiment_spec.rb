# frozen_string_literal: true

require Rails.root.join("db", "data", "20231109143922_set_up_bangladesh_december_experiment.rb")
require Rails.root.join("db", "data", "20231127065753_update_facility_list_for_bd_december_experiment.rb")

require "rails_helper"

describe UpdateFacilityListForBdDecemberExperiment do
  before do
    allow(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")
  end

  context "experiments already exist and the data migration is run" do
    it "updates existing December experiments with new region filters" do
      SetUpBangladeshDecemberExperiment.new.up
      experiment = Experimentation::Experiment.find_by_name("Current Patient December 2023")
      old_facility_list = experiment.filters.dig("facilities", "include")

      described_class.new.up
      current_experiment = Experimentation::Experiment.find_by_name("Current Patient December 2023")
      stale_experiment = Experimentation::Experiment.find_by_name("Stale Patient December 2023")
      new_facility_list_current = current_experiment.filters.dig("facilities", "include")
      new_facility_list_stale = stale_experiment.filters.dig("facilities", "include")

      expect(new_facility_list_current).not_to match_array(old_facility_list)
      expect(new_facility_list_current.count).to eq(54)
      expect(new_facility_list_stale).not_to match_array(old_facility_list)
      expect(new_facility_list_stale.count).to eq(54)
    end
  end

  context "the data migration is rolled back" do
    it "reverts the experiment filters to the old list of facilities without errors" do
      SetUpBangladeshDecemberExperiment.new.up
      experiment = Experimentation::Experiment.find_by_name("Current Patient December 2023")
      old_facility_list = experiment.filters.dig("facilities", "include")

      described_class.new.up

      expect {
        described_class.new.down
      }.not_to raise_error

      current_experiment = Experimentation::Experiment.find_by_name("Current Patient December 2023")
      stale_experiment = Experimentation::Experiment.find_by_name("Stale Patient December 2023")
      new_facility_list_current = current_experiment.filters.dig("facilities", "include")
      new_facility_list_stale = stale_experiment.filters.dig("facilities", "include")

      expect(new_facility_list_current).to match_array(old_facility_list)
      expect(new_facility_list_current.count).to eq(73)
      expect(new_facility_list_stale).to match_array(old_facility_list)
      expect(new_facility_list_stale.count).to eq(73)
    end
  end
end
