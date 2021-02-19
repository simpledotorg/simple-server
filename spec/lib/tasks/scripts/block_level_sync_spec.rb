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
      enable_time = Time.new("2018-1-1")

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

  describe ".set_percentage" do
    it "enables a percentage of users randomly" do
      _users = create_list(:user, 20)
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      BlockLevelSync.set_percentage(95)

      expect(Flipper[:block_level_sync].percentage_of_actors_value).to eq(95)
    end

    it "increases the percentage" do
      users = create_list(:user, 20)
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      BlockLevelSync.set_percentage(95)

      expect(Flipper[:block_level_sync].percentage_of_actors_value).to eq(95)

      BlockLevelSync.set_percentage(100)

      expect(users.map(&:block_level_sync?).count(&:itself)).to eq(20)
      expect(Flipper[:block_level_sync].percentage_of_actors_value).to eq(100)
    end

    it "touches the facilities for the users" do
      users = create_list(:user, 20)
      enable_time = Time.new("2018-1-1 4:08:15")
      allow(Reports::RegionCacheWarmer).to receive(:call).and_return(true)

      Timecop.freeze(enable_time) do
        BlockLevelSync.set_percentage(100)
      end

      users.each do |u|
        u.facility_group.facilities.pluck(:updated_at).each do |t|
          expect(t.to_i).to eq(enable_time.to_i)
        end
      end
    end

    it "calls the region cache warmer" do
      _users = create_list(:user, 2)
      expect(Reports::RegionCacheWarmer).to receive(:call)
      BlockLevelSync.set_percentage(50)
    end
  end
end
