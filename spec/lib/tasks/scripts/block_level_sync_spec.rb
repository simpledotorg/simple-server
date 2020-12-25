require "rails_helper"
require "tasks/scripts/block_level_sync"

RSpec.describe BlockLevelSync do
  describe ".enable" do
    it "enables the specified user_ids" do
      enabled_users = create_list(:user, 5)
      not_enabled_users = create_list(:user, 5)

      BlockLevelSync.enable(enabled_users)

      enabled_users.each do |u|
        expect(u.block_level_sync?).to eq(true)
      end

      not_enabled_users.each do |u|
        expect(u.block_level_sync?).to eq(false)
      end
    end

    it "touches the facilities for the user" do
      enabled_users = create_list(:user, 5)
      enable_time = 10.minutes.ago

      Timecop.freeze(enable_time) do
        BlockLevelSync.enable(enabled_users)
      end

      enabled_users.each do |u|
        u.facility_group.facilities.pluck(:updated_at).each do |t|
          expect(t.to_i).to eq(enable_time.to_i)
        end
      end
    end
  end

  describe ".disable" do
    it "disables the specified user_ids" do
      enabled_users = create_list(:user, 5)
      not_enabled_users = create_list(:user, 5)

      BlockLevelSync.enable(enabled_users)

      enabled_users.each do |u|
        expect(u.block_level_sync?).to eq(true)
      end

      BlockLevelSync.disable(enabled_users)

      enabled_users.each do |u|
        expect(u.block_level_sync?).to eq(false)
      end

      not_enabled_users.each do |u|
        expect(u.block_level_sync?).to eq(false)
      end
    end
  end

  describe ".bump" do
    it "enables a percentage of users randomly" do
      users = create_list(:user, 20)
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      BlockLevelSync.bump(95)

      expect(users.map(&:block_level_sync?).count(&:itself)).to be_between(17, 21)
    end

    it "increases the percentage" do
      users = create_list(:user, 20)
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      BlockLevelSync.bump(95)

      expect(users.map(&:block_level_sync?).count(&:itself)).to be_between(17, 21)

      BlockLevelSync.bump(5)

      expect(users.map(&:block_level_sync?).count(&:itself)).to eq(20)
    end

    it "touches the facilities for the users" do
      users = create_list(:user, 20)
      enable_time = 10.minutes.ago
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      Timecop.freeze(enable_time) do
        BlockLevelSync.bump(95)
      end

      users.each do |u|
        u.facility_group.facilities.pluck(:updated_at).each do |t|
          expect(t.to_i).to eq(enable_time.to_i)
        end
      end
    end

    it "calls the region cache warmer" do
      create_list(:user, 2)
      expect(Reports::RegionCacheWarmer).to receive(:call)
      BlockLevelSync.bump(50)
    end
  end
end
