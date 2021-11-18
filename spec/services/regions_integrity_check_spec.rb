require "rails_helper"

RSpec.describe RegionsIntegrityCheck, type: :model do
  let!(:organization) { create(:organization) }
  let!(:state) { create(:region, :state, reparent_to: organization.region) }
  let!(:facility_groups) { create_list(:facility_group, 2, state: state.name, organization: organization) }
  let!(:block_1) { create(:region, :block, name: "B1", reparent_to: facility_groups[0].region) }
  let!(:block_2) { create(:region, :block, name: "B2", reparent_to: facility_groups[1].region) }
  let!(:facility_1) { create(:facility, state: state.name, block: block_1.name, facility_group: facility_groups[0]) }
  let!(:facility_2) { create(:facility, state: state.name, block: block_2.name, facility_group: facility_groups[1]) }

  context "missing regions" do
    it "tracks missing org" do
      orgs = create_list(:organization, 2)
      orgs.each { |org| org.region.delete }

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:organizations, :missing_regions)).to match_array(orgs.pluck(:id))
    end

    it "tracks missing state" do
      missing_state = "Goa"
      facilities_without_region = create_list(:facility, 2, state: missing_state, block: block_1.name, facility_group: facility_groups[0])
      facilities_without_region.each { |facility| facility.region.delete }

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:states, :missing_regions)).to match_array([[missing_state, organization.id]])
      expect(swept.inconsistencies.dig(:facilities, :missing_regions)).to match_array(facilities_without_region.map(&:id))
    end

    it "tracks missing facility_groups" do
      groups = create_list(:facility_group, 2, state: state.name)
      groups.each { |fg| fg.region.delete }

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:districts, :missing_regions)).to match_array(groups.pluck(:id))
    end

    it "tracks missing blocks" do
      _remove_block_regions = Region.block_regions.delete_all

      swept = RegionsIntegrityCheck.call
      expected = [[block_1.name, facility_groups[0].id], [block_2.name, facility_groups[1].id]]

      expect(swept.inconsistencies.dig(:blocks, :missing_regions)).to match_array(expected)
    end

    it "tracks missing facilities" do
      facilities_without_region = create_list(:facility, 2, state: state.name, block: block_1.name, facility_group: facility_groups[0])
      facilities_without_region.each { |facility| facility.region.delete }

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:facilities, :missing_regions)).to match_array(facilities_without_region.map(&:id))
    end
  end

  context "duplicate regions for the same source" do
    it "tracks duplicate orgs" do
      duplicates =
        create_list(:region, 2, source: organization, region_type: :organization, reparent_to: Region.root)
          .yield_self { |orgs| orgs << organization.region }
          .map(&:id)

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:organizations, :duplicate_regions)).to match_array(duplicates)
    end

    it "tracks duplicate states" do
      duplicates =
        create_list(:region, 2, :state, name: state.name, reparent_to: organization.region)
          .yield_self { |states| states << state }
          .map(&:id)

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:states, :duplicate_regions)).to match_array(duplicates)
    end

    it "tracks duplicate facility groups" do
      duplicates =
        create_list(:region, 2, region_type: :district, source: facility_groups[0], reparent_to: state)
          .yield_self { |districts| districts << facility_groups[0].region }
          .map(&:id)

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:districts, :duplicate_regions)).to match_array(duplicates)
    end

    it "tracks duplicate blocks" do
      duplicates =
        create_list(:region, 2, :block, name: block_1.name, reparent_to: facility_groups[0].region)
          .yield_self { |blocks| blocks << block_1 }
          .map(&:id)

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:blocks, :duplicate_regions)).to match_array(duplicates)
    end

    it "tracks duplicate facilities" do
      duplicates = create_list(:region, 2, region_type: :facility, source: facility_1, reparent_to: block_1)
        .yield_self { |facilities| facilities << facility_1.region }
        .map(&:id)

      swept = RegionsIntegrityCheck.call

      expect(swept.inconsistencies.dig(:facilities, :duplicate_regions)).to match_array(duplicates)
    end
  end

  context "logging" do
    it "logs errors" do
      # block regions are missing
      _remove_block_regions = Region.block_regions.delete_all

      expected_log = {
        class: "RegionsIntegrityCheck",
        msg: {
          resource: :blocks,
          result: {missing_regions: array_including(["B2", facility_groups[1].id], ["B1", facility_groups[0].id])}
        }
      }

      expect(Rails.logger).to receive(:error).with(expected_log)

      RegionsIntegrityCheck.call
    end

    it "does not log errors where there are none" do
      expect(Rails.logger).to_not receive(:error)

      RegionsIntegrityCheck.call
    end
  end

  context "sentry" do
    it "reports errors to sentry" do
      # block regions are missing
      _remove_block_regions = Region.block_regions.delete_all

      expected_msg = [
        "Regions Integrity Failure",
        {
          extra: {
            resource: :blocks,
            result:
              {
                missing_regions: array_including(["B2", facility_groups[1].id], ["B1", facility_groups[0].id])
              }
          },
          tags: {type: "regions"}
        }
      ]

      expect(Sentry).to receive(:capture_message).with(*expected_msg)

      RegionsIntegrityCheck.call
    end

    it "does not report errors if there are none" do
      expect(Sentry).to_not receive(:capture_message)

      RegionsIntegrityCheck.call
    end
  end
end
