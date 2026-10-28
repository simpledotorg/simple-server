# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/move_region"

RSpec.describe MoveRegion, type: :model do
  let(:root) { Region.root }
  let(:organization) { create(:region, :organization, reparent_to: root) }
  let(:state) { create(:region, :state, name: "Test State", reparent_to: organization) }
  let(:old_district) { create(:region, :district, name: "Old District", reparent_to: state) }
  let(:new_district) { create(:region, :district, name: "New District", reparent_to: state) }
  let(:block) { create(:region, :block, name: "Test Block", reparent_to: old_district) }
  let(:facility_region) { create(:region, :facility, name: "Test Facility", reparent_to: block) }

  describe "#initialize" do
    it "initializes successfully with valid slugs" do
      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      expect(mover.region).to eq(block)
      expect(mover.new_parent).to eq(new_district)
      expect(mover.old_parent).to eq(old_district)
    end

    it "raises error if region not found" do
      expect {
        MoveRegion.new(region_slug: "nonexistent", new_parent_slug: new_district.slug)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises error if new parent not found" do
      expect {
        MoveRegion.new(region_slug: block.slug, new_parent_slug: "nonexistent")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises error if trying to move to invalid parent type" do
      # Can't move a block to a state (should go to district)
      another_state = create(:region, :state, reparent_to: organization)
      expect {
        MoveRegion.new(region_slug: block.slug, new_parent_slug: another_state.slug)
      }.to raise_error(ArgumentError, /Cannot move block to state/)
    end

    it "raises error if trying to move to itself" do
      expect {
        MoveRegion.new(region_slug: block.slug, new_parent_slug: block.slug)
      }.to raise_error(ArgumentError, /Cannot move region to itself/)
    end

    it "raises error if trying to move to own descendant" do
      expect {
        MoveRegion.new(region_slug: block.slug, new_parent_slug: facility_region.slug)
      }.to raise_error(ArgumentError, /Cannot move region to itself or its own descendant/)
    end

    it "raises error if trying to move root region" do
      expect {
        MoveRegion.new(region_slug: root.slug, new_parent_slug: organization.slug)
      }.to raise_error(ArgumentError, /Cannot move root region/)
    end
  end

  describe "#move! with dry_run: true" do
    it "returns analysis without making changes" do
      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      old_path = block.path.to_s

      result = mover.move!(dry_run: true)

      expect(result).to include(
        region: "Test Block",
        old_parent: "Old District",
        new_parent: "New District"
      )

      # Verify no changes were made
      block.reload
      expect(block.path.to_s).to eq(old_path)
    end

    it "counts affected facilities correctly" do
      # Create multiple facilities under the block
      create(:region, :facility, reparent_to: block)
      create(:region, :facility, reparent_to: block)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      result = mover.move!(dry_run: true)

      expect(result[:affected_facilities]).to eq(2)
    end
  end

  describe "#move! with dry_run: false" do
    it "successfully moves a block to a new district" do
      old_path = block.path.to_s
      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)

      result = mover.move!(dry_run: false)

      expect(result[:region_updated]).to be true
      expect(result[:caches_cleared]).to be true

      # Verify the move
      block.reload
      expect(block.path.to_s).not_to eq(old_path)
      expect(block.district_region).to eq(new_district)
    end

    it "updates descendant facility paths" do
      facility_region = create(:region, :facility, name: "Test Facility", reparent_to: block)
      old_facility_path = facility_region.path.to_s

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      mover.move!(dry_run: false)

      facility_region.reload
      expect(facility_region.path.to_s).not_to eq(old_facility_path)
      expect(facility_region.path.to_s).to include(new_district.slug.tr("-", "_"))
    end

    it "counts updated descendants" do
      # Create facilities under the block
      facility1 = create(:region, :facility, reparent_to: block)
      facility2 = create(:region, :facility, reparent_to: block)

      # Verify they're descendants
      expect(facility1.path.to_s).to start_with(block.path.to_s)
      expect(facility2.path.to_s).to start_with(block.path.to_s)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      result = mover.move!(dry_run: false)

      # Should update 2 facility regions
      expect(result[:descendants_updated]).to eq(2)
    end

    it "recalculates populations when moving districts" do
      # Create district
      district_with_pop = create(:region, :district, reparent_to: state)
      another_state = create(:region, :state, reparent_to: organization)

      # Mock the recalculation methods - expect to be called at least once
      allow_any_instance_of(Region).to receive(:recalculate_state_population!)
      allow_any_instance_of(Region).to receive(:recalculate_state_diabetes_population!)

      mover = MoveRegion.new(
        region_slug: district_with_pop.slug,
        new_parent_slug: another_state.slug
      )
      result = mover.move!(dry_run: false)

      expect(result[:region_updated]).to be true
    end

    it "clears caches for affected regions" do
      expect(Rails.cache).to receive(:delete_matched).at_least(:once)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      mover.move!(dry_run: false)
    end

    it "refreshes reporting views" do
      expect(RefreshReportingViews).to receive(:call)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      mover.move!(dry_run: false)
    end

    it "runs integrity check after move" do
      expect(RegionsIntegrityCheck).to receive(:call)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      mover.move!(dry_run: false)
    end

    it "rolls back on error" do
      old_path = block.path.to_s

      # Force an error during the move
      allow_any_instance_of(MoveRegion).to receive(:update_descendant_paths_by_ids).and_raise("Simulated error")

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)

      expect {
        mover.move!(dry_run: false)
      }.to raise_error("Simulated error")

      # Verify rollback
      block.reload
      expect(block.path.to_s).to eq(old_path)
    end
  end

  describe "real-world scenario: Moving Hulla Woreda" do
    let(:ethiopia_org) { create(:region, :organization, name: "Ethiopia MoH", reparent_to: root) }
    let(:sidama_state) { create(:region, :state, name: "Sidama", reparent_to: ethiopia_org) }
    let(:northern_zone) { create(:region, :district, name: "Northern Zone", reparent_to: sidama_state) }
    let(:southern_zone) { create(:region, :district, name: "Southern Zone", reparent_to: sidama_state) }
    let(:hulla_woreda) { create(:region, :block, name: "Hulla Woreda", reparent_to: northern_zone) }

    before do
      # Force creation of regions
      ethiopia_org
      sidama_state
      northern_zone
      southern_zone
      hulla_woreda

      # Create facilities under Hulla Woreda
      3.times do |i|
        create(:region, :facility, name: "Facility #{i + 1}", reparent_to: hulla_woreda)
      end
    end

    it "successfully moves Hulla Woreda from Northern Zone to Southern Zone" do
      # Verify initial state
      expect(hulla_woreda.district_region).to eq(northern_zone)

      # Verify facilities exist BEFORE move
      initial_facilities = Region.where("path <@ ?::ltree", hulla_woreda.path.to_s)
        .where(region_type: "facility")

      # Store old paths for comparison
      old_facility_paths = initial_facilities.map { |f| {name: f.name, path: f.path.to_s} }

      expect(initial_facilities.count).to eq(3), "Expected 3 facilities before move, found #{initial_facilities.count}. Paths: #{old_facility_paths.inspect}"

      # Perform dry run
      mover = MoveRegion.new(
        region_slug: hulla_woreda.slug,
        new_parent_slug: southern_zone.slug
      )
      dry_run_result = mover.move!(dry_run: true)

      expect(dry_run_result[:region]).to eq("Hulla Woreda")
      expect(dry_run_result[:old_parent]).to eq("Northern Zone")
      expect(dry_run_result[:new_parent]).to eq("Southern Zone")
      expect(dry_run_result[:affected_facilities]).to eq(3)

      # Perform actual move
      result = mover.move!(dry_run: false)

      expect(result[:region_updated]).to be true
      expect(result[:descendants_updated]).to eq(3)

      # Verify final state - reload from DB
      hulla_woreda.reload
      expect(hulla_woreda.district_region).to eq(southern_zone)

      # Query all facilities after move to see what happened
      all_facilities_after = Region.where(region_type: "facility").map { |f| {name: f.name, path: f.path.to_s} }

      # Query facilities under new hulla path
      facilities = Region.where("path <@ ?::ltree", hulla_woreda.path.to_s)
        .where(region_type: "facility")

      # Build detailed error message
      error_msg = "Expected 3 facilities after move under new path, found #{facilities.count}.\n"
      error_msg += "Hulla new path: #{hulla_woreda.path}\n"
      error_msg += "Old facility paths: #{old_facility_paths.inspect}\n"
      error_msg += "All facility paths after move: #{all_facilities_after.inspect}"

      expect(facilities.count).to eq(3), error_msg

      # Verify all facility paths were updated
      facilities.each do |facility_region|
        expect(facility_region.path.to_s).to include("southern_zone")
        expect(facility_region.path.to_s).not_to include("northern_zone")
      end
    end
  end

  describe "validation edge cases" do
    it "allows moving facility from one block to another" do
      another_block = create(:region, :block, reparent_to: old_district)
      facility = create(:region, :facility, reparent_to: block)

      expect {
        MoveRegion.new(region_slug: facility.slug, new_parent_slug: another_block.slug)
      }.not_to raise_error
    end

    it "allows moving organization to root" do
      expect {
        MoveRegion.new(region_slug: organization.slug, new_parent_slug: root.slug)
      }.not_to raise_error
    end

    it "prevents moving state to root (should go to organization)" do
      expect {
        MoveRegion.new(region_slug: state.slug, new_parent_slug: root.slug)
      }.to raise_error(ArgumentError, /Only organizations can be direct children of root/)
    end
  end

  describe "facility field updates" do
    it "updates facility model fields when moving a facility" do
      facility_group = create(:facility_group)
      old_district.update!(source: facility_group)

      # Create new_block - new_district will get facility_group from region creation
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility", facility_group: facility_group, zone: block.name, district: old_district.name, state: state.name)
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      # Mock background jobs
      allow(Reports::Month).to receive(:all).and_return([])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)
      mover.move!(dry_run: false, skip_reporting_refresh: true)

      facility.reload
      expect(facility.zone).to eq(new_block.name)
      expect(facility.district).to eq(new_district.name)
      expect(facility.state).to eq(state.name)
    end

    it "updates facility model fields when moving a block" do
      facility_group = create(:facility_group)
      old_district.update!(source: facility_group)

      facility = create(:facility, name: "Test Facility", facility_group: facility_group, zone: block.name, district: old_district.name, state: state.name)
      create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      # Mock background jobs
      allow(Reports::Month).to receive(:all).and_return([])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      mover = MoveRegion.new(region_slug: block.slug, new_parent_slug: new_district.slug)
      mover.move!(dry_run: false, skip_reporting_refresh: true)

      facility.reload
      expect(facility.zone).to eq(block.name)
      expect(facility.district).to eq(new_district.name)
      expect(facility.state).to eq(state.name)
    end

    it "updates updated_at for mobile sync" do
      facility_group = create(:facility_group)
      old_district.update!(source: facility_group)

      # Create new_block first - this ensures new_district has block children
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility", facility_group: facility_group, zone: block.name, district: old_district.name, state: state.name)
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      old_updated_at = facility.updated_at
      # Ensure time passes
      sleep 0.01

      # Mock background jobs
      allow(Reports::Month).to receive(:all).and_return([])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)
      mover.move!(dry_run: false, skip_reporting_refresh: true)

      facility.reload
      expect(facility.updated_at).to be > old_updated_at
    end

    it "allows facility to be updated after move and stays under new block" do
      facility_group = create(:facility_group)
      old_district.update!(source: facility_group)

      # Create facility_group for new_district and properly link the region association
      new_district_facility_group = create(:facility_group)
      # Delete the auto-created region so we can use new_district as the region
      new_district_facility_group.region&.destroy
      new_district.update!(source: new_district_facility_group)
      # Now create new_block - it will be under new_district
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility", facility_group: facility_group, zone: block.name, district: old_district.name, state: state.name)
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      # Mock background jobs
      allow(Reports::Month).to receive(:all).and_return([])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)
      mover.move!(dry_run: false, skip_reporting_refresh: true)

      # Completely reload facility from database to clear all cached associations
      facility = Facility.find(facility.id)

      # After move, facility should have new zone, district, and facility_group
      expect(facility.zone).to eq(new_block.name)
      expect(facility.district).to eq(new_district.name)
      expect(facility.facility_group_id).to eq(new_district_facility_group.id)

      expect {
        facility.update!(name: "Updated Facility Name")
      }.not_to raise_error

      facility_region.reload
      expect(facility_region.block_region).to eq(new_block)
      expect(facility_region.district_region).to eq(new_district)
    end
  end

  describe "historical reporting refresh" do
    it "queues background job to refresh base materialized views" do
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility")
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)

      allow(Reports::Month).to receive(:all).and_return([])
      expect(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      mover.move!(dry_run: false, skip_reporting_refresh: true)
    end

    it "queues background jobs to refresh partitioned tables" do
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility")
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)

      # Mock Reports::Month.all to return some months
      allow(Reports::Month).to receive(:all).and_return([
        double(month_date: Date.new(2024, 1, 1)),
        double(month_date: Date.new(2024, 2, 1))
      ])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      # Mock the chained method calls
      job_double = double(perform_async: true)
      expect(RefreshReportingPartitionedTableJob).to receive(:set).at_least(:once).and_return(job_double)

      mover.move!(dry_run: false, skip_reporting_refresh: true)
    end

    it "staggers jobs over time to avoid database overload" do
      new_block = create(:region, :block, name: "New Block", reparent_to: new_district)

      facility = create(:facility, name: "Test Facility")
      facility_region = create(:region, :facility, name: "Test Facility", source: facility, reparent_to: block)

      mover = MoveRegion.new(region_slug: facility_region.slug, new_parent_slug: new_block.slug)

      # Mock Reports::Month.all
      allow(Reports::Month).to receive(:all).and_return([
        double(month_date: Date.new(2024, 1, 1)),
        double(month_date: Date.new(2024, 2, 1))
      ])
      allow(RefreshBaseMaterializedViewsJob).to receive(:perform_async)

      delays = []
      allow(RefreshReportingPartitionedTableJob).to receive(:set) do |options|
        delays << options[:wait_until]
        double(perform_async: true)
      end

      mover.move!(dry_run: false, skip_reporting_refresh: true)

      expect(delays.uniq.length).to be > 1
    end
  end
end
