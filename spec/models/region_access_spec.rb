# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegionAccess, type: :model do
  let(:manager) { create(:admin, :manager, full_name: "manager") }

  context "accessing from User" do
    it "can be accessed via user" do
      expect(User.new(access_level: :manager).region_access).to be_instance_of(RegionAccess)
    end

    it "is not memoized by default" do
      facility_group = create(:facility_group, name: "district")
      district = facility_group.region
      user = manager
      user.accesses.create!(resource: district.source)

      region_access = user.region_access
      expect(region_access).to be_instance_of(RegionAccess)
      expect(region_access.user_access).to receive(:accessible_district_regions).and_call_original.exactly(2).times
      expect(region_access.accessible_district?(district, :view_reports)).to be true
      expect(region_access.accessible_district?(district, :view_reports)).to be true
    end

    it "can return a memoized version" do
      facility_group = create(:facility_group, name: "district")
      district = facility_group.region
      other_district = create(:facility_group, name: "other district").region
      user = manager
      user.accesses.create!(resource: district.source)

      region_access = user.region_access(memoized: true)
      expect(region_access).to be_instance_of(RegionAccess)
      expect(region_access.user_access).to receive(:accessible_district_regions).and_call_original.once
      expect(region_access.accessible_district?(district, :view_reports)).to be true
      expect(region_access.accessible_district?(district, :view_reports)).to be true
      expect(region_access.accessible_district?(other_district, :view_reports)).to be false
    end
  end
end
