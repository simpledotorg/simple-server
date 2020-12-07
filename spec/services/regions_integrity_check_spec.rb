require "rails_helper"

RSpec.describe RegionsIntegrityCheck, type: :model do
  before do
    enable_flag(:regions_prep)
  end

  let!(:organization) { create(:organization) }
  let!(:state) { create(:region, :state, reparent_to: organization.region) }
  let!(:facility_groups) { create_list(:facility_group, 2, state: state.name, organization: organization) }
  let!(:block_1) { create(:region, :block, name: "B1", reparent_to: facility_groups[0].region) }
  let!(:block_2) { create(:region, :block, name: "B2", reparent_to: facility_groups[1].region) }
  let!(:facility_1) { create(:facility, state: state.name, block: block_1.name, facility_group: facility_groups[0]) }
  let!(:facility_2) { create(:facility, state: state.name, block: block_2.name, facility_group: facility_groups[1]) }

  context "missing regions" do
    it "tracks missing org" do
      orgs_without_region = Organization.import(build_list(:organization, 2)).ids

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:organizations, :missing_regions)).to match_array(orgs_without_region)
    end

    it "tracks missing state" do
      missing_state = "Goa"
      facilities_without_region =
        build_list(:facility, 2, state: missing_state, block: block_1.name, facility_group: facility_groups[0])
          .yield_self { |facilities| Facility.import(facilities) }
          .ids

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:states, :missing_regions)).to match_array(missing_state)
      expect(swept.errors.dig(:facilities, :missing_regions)).to match_array(facilities_without_region)
    end

    it "tracks missing facility_groups" do
      fgs_without_region = FacilityGroup.import(build_list(:facility_group, 2, state: state.name)).ids

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:facility_groups, :missing_regions)).to match_array(fgs_without_region)
    end

    it "tracks missing blocks" do
      _remove_block_regions = Region.block_regions.delete_all

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:blocks, :missing_regions)).to match_array([block_1.name, block_2.name])
    end

    it "tracks missing facilities" do
      facilities_without_region =
        build_list(:facility, 2, state: state.name, block: block_1.name, facility_group: facility_groups[0])
          .yield_self { |facilities| Facility.import(facilities) }
          .ids

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:facilities, :missing_regions)).to match_array(facilities_without_region)
    end
  end

  context "tracks the count of missing sources" do
    it "tracks missing orgs" do
      create(:region, region_type: :organization, reparent_to: Region.root)

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:organizations, :regions_without_sources_count)).to eq(1)
    end

    it "tracks missing states" do
      create(:region, :state, reparent_to: organization.region)

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:states, :regions_without_sources_count)).to eq(1)
    end

    it "tracks missing facility groups" do
      create(:region, region_type: :district, reparent_to: state)

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:facility_groups, :regions_without_sources_count)).to eq(1)
    end

    it "tracks missing blocks" do
      create(:region, :block, reparent_to: facility_groups[0].region)

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:blocks, :regions_without_sources_count)).to eq(1)
    end

    it "tracks missing facilities" do
      create(:region, region_type: :facility, reparent_to: block_1)

      swept = RegionsIntegrityCheck.sweep

      expect(swept.errors.dig(:facilities, :regions_without_sources_count)).to eq(1)
    end
  end

  context "logging" do
    it "logs errors" do
      # block regions are missing
      _remove_block_regions = Region.block_regions.delete_all

      expected_log = {
        class: "RegionsIntegrityCheck",
        msg: [{blocks: {missing_regions: %w[B2 B1], regions_without_sources_count: 0, extra_regions_for_source: []}}]
      }

      expect(Rails.logger).to receive(:error).with(expected_log)

      RegionsIntegrityCheck.sweep
    end

    it "does not log errors where there are none" do
      expect(Rails.logger).to_not receive(:error)

      RegionsIntegrityCheck.sweep
    end
  end

  context "sentry" do
    it "reports errors to sentry" do
      # block regions are missing
      _remove_block_regions = Region.block_regions.delete_all

      expected_msg = [
        "Regions Integrity Failure",
        {
          extra: [{blocks: {missing_regions: %w[B2 B1], regions_without_sources_count: 0, extra_regions_for_source: []}}],
          logger: "logger",
          tags: {type: "regions"}
        }
      ]

      expect(Raven).to receive(:capture_message).with(*expected_msg)

      RegionsIntegrityCheck.sweep
    end

    it "does not report errors if there are none" do
      expect(Raven).to_not receive(:capture_message)

      RegionsIntegrityCheck.sweep
    end
  end
end
