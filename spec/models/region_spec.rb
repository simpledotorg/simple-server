require "rails_helper"

RSpec.describe Region, type: :model do
  describe "validations" do
    it "requires a region type" do
      region = Region.new(name: "foo", path: "foo")
      expect(region).to_not be_valid
      expect(region.errors[:region_type]).to eq(["can't be blank"])
    end
  end

  describe "slugs" do
    it "handles duplicate names nicely when creating a slug" do
      region_1 = Region.create!(name: "New York", region_type: "state", reparent_to: Region.root)
      region_2 = Region.create!(name: "New York", region_type: "district", reparent_to: region_1)
      region_3 = Region.create!(name: "New York", region_type: "block", reparent_to: region_2)
      region_4 = Region.create!(name: "New York", region_type: "facility", reparent_to: region_3)
      region_5 = Region.create!(name: "New York", region_type: "facility", reparent_to: region_3)

      expect(region_1.slug).to eq("new-york")
      expect(region_2.slug).to eq("new-york-district")
      expect(region_3.slug).to eq("new-york-block")
      expect(region_4.slug).to eq("new-york-facility")
      expect(region_5.slug).to match(/new-york-facility-[[:alnum:]]{8}$/)
    end
  end

  describe "when Region sources are destroyed" do
    it "destroys the region if there are no children" do
      facility_group = create(:facility_group, name: "no-children")
      district_region = facility_group.region
      facility_group.destroy!
      expect(Region.exists?(district_region.id)).to be false
    end

    it "does not destroys the region if there are children" do
      facility_group = create(:facility_group, name: "no-children")
      district_region = facility_group.region
      facility_group.facilities << create(:facility, facility_group: facility_group)
      facility_group.destroy!
      expect(Region.exists?(district_region.id)).to be true
    end
  end

  describe "localized_region_type" do
    it "returns country specific names" do
      state = build(:region, region_type: :state)
      district = build(:region, region_type: :district)
      block = build(:region, region_type: :block)
      facility = build(:region, region_type: :facility)
      I18n.with_locale(:en_IN) do
        expect(state.localized_region_type).to eq("state")
        expect(district.localized_region_type).to eq("district")
        expect(block.localized_region_type).to eq("block")
        expect(facility.localized_region_type).to eq("facility")
      end
      I18n.with_locale(:en_BD) do
        expect(state.localized_region_type).to eq("division")
        expect(district.localized_region_type).to eq("district")
        expect(block.localized_region_type).to eq("upazila")
        expect(facility.localized_region_type).to eq("facility")
      end
      I18n.with_locale(:en_ET) do
        expect(state.localized_region_type).to eq("region")
        expect(district.localized_region_type).to eq("zone")
        expect(block.localized_region_type).to eq("woreda")
        expect(facility.localized_region_type).to eq("facility")
      end
    end

    it "has a fallback for default locale (which is the same as the India region_types)" do
      state = build(:region, region_type: :state)
      district = build(:region, region_type: :district)
      block = build(:region, region_type: :block)
      facility = build(:region, region_type: :facility)
      expect(I18n.locale).to eq(:en)
      expect(state.localized_region_type).to eq("state")
      expect(district.localized_region_type).to eq("district")
      expect(block.localized_region_type).to eq("block")
      expect(facility.localized_region_type).to eq("facility")
    end
  end

  describe "localized_child_region_type" do
    it "returns country specific names" do
      state = build(:region, region_type: :state)
      district = build(:region, region_type: :district)
      block = build(:region, region_type: :block)
      facility = build(:region, region_type: :facility)
      I18n.with_locale(:en_IN) do
        expect(state.localized_child_region_type).to eq("district")
        expect(district.localized_child_region_type).to eq("block")
        expect(block.localized_child_region_type).to eq("facility")
        expect(facility.localized_child_region_type).to be_nil
      end
      I18n.with_locale(:en_BD) do
        expect(state.localized_child_region_type).to eq("district")
        expect(district.localized_child_region_type).to eq("upazila")
        expect(block.localized_child_region_type).to eq("facility")
        expect(facility.localized_child_region_type).to be_nil
      end
      I18n.with_locale(:en_ET) do
        expect(state.localized_child_region_type).to eq("zone")
        expect(district.localized_child_region_type).to eq("woreda")
        expect(block.localized_child_region_type).to eq("facility")
        expect(facility.localized_child_region_type).to be_nil
      end
    end

    it "has a fallback for default locale (which is the same as the India region_types)" do
      state = build(:region, region_type: :state)
      district = build(:region, region_type: :district)
      block = build(:region, region_type: :block)
      facility = build(:region, region_type: :facility)
      expect(I18n.locale).to eq(:en)
      expect(state.localized_child_region_type).to eq("district")
      expect(district.localized_child_region_type).to eq("block")
      expect(block.localized_child_region_type).to eq("facility")
      expect(facility.localized_child_region_type).to be_nil
    end
  end

  describe "region_type" do
    it "has question methods for determining type" do
      region_1 = Region.create!(name: "New York", region_type: "state", reparent_to: Region.root)
      region_2 = Region.create!(name: "New York", region_type: "district", reparent_to: region_1)
      region_3 = Region.create!(name: "New York", region_type: "block", reparent_to: region_2)
      region_4 = Region.create!(name: "New York", region_type: "facility", reparent_to: region_3)
      expect(region_1).to be_state_region
      expect(region_2.district_region?).to be_truthy
      expect(region_3.block_region?).to be_truthy
      expect(region_4.facility_region?).to be_truthy
    end

    it "can determine child region type" do
      state = Region.new(name: "New York", region_type: "state")
      expect(state.child_region_type).to eq("district")
      district = Region.new(region_type: "district")
      expect(district.child_region_type).to eq("block")
      district = Region.new(region_type: "facility")
      expect(district.child_region_type).to be_nil
    end
  end

  describe "reportable_children" do
    it "is everything for India" do
      expect(CountryConfig).to receive(:current).and_return(CountryConfig.for(:IN)).at_least(:once)

      org = Seed.seed_org.region
      state = FactoryBot.create(:region, :state, reparent_to: Seed.seed_org.region)
      district = FactoryBot.create(:region, :district, reparent_to: state)
      fg = FactoryBot.create(:facility_group, region: district)
      facility = FactoryBot.create(:facility, facility_group: fg)
      expect(org.reportable_children).to match_array([state])
      expect(district.reportable_children).to match_array(district.block_regions)
      expect(district.block_regions.first.reportable_children).to match_array([facility.region])
    end

    it "is everything for Bangladesh" do
      expect(CountryConfig).to receive(:current).and_return(CountryConfig.for(:BD)).at_least(:once)

      org = Seed.seed_org.region
      state = FactoryBot.create(:region, :state, reparent_to: org)
      district = FactoryBot.create(:region, :district, reparent_to: state)
      fg = FactoryBot.create(:facility_group, region: district)
      facility = FactoryBot.create(:facility, facility_group: fg)
      expect(org.reportable_children).to match_array([state])
      expect(district.reportable_children).to match_array(district.block_regions)
      expect(district.block_regions.first.reportable_children).to match_array([facility.region])
    end
  end

  describe "cache_key" do
    it "contains class name, region type, and id" do
      facility_group = create(:facility_group)
      region = facility_group.region
      expect(region.cache_key).to eq("regions/district/#{region.id}")
      expect(facility_group.cache_key).to eq(region.cache_key)
    end
  end

  describe "facilities" do
    it "returns the source facilities" do
      facility_group = create(:facility_group)
      facilities = create_list(:facility, 3, block: "Block ABC", facility_group: facility_group)

      facility = facilities.first
      block_region = facility.region.parent
      district_region = block_region.parent
      expect(block_region.facilities).to contain_exactly(*facilities)
      expect(district_region.facilities).to contain_exactly(*facilities)
      expect(district_region.organization_region.facilities).to contain_exactly(*facilities)
    end

    it "gets assigned patients via facilities" do
      facility_group = create(:facility_group)
      block_1_facilities = create_list(:facility, 3, block: "Block 1", facility_group: facility_group)
      block_2_facility = create(:facility, block: "Block 2", facility_group: facility_group)
      patients_in_block_1 = block_1_facilities.each_with_object([]) { |facility, ary|
        ary << create(:patient, registration_facility: facility)
      }
      patients_in_block_2 = create_list(:patient, 2, registration_facility: block_2_facility)
      block_1 = Region.block_regions.find_by!(name: "Block 1")
      block_2 = Region.block_regions.find_by!(name: "Block 2")
      expect(block_2_facility.region.assigned_patients).to match_array(patients_in_block_2)
      expect(block_1.assigned_patients).to match_array(patients_in_block_1)
      expect(block_2.assigned_patients).to match_array(patients_in_block_2)
      expect(facility_group.region.assigned_patients).to match_array(patients_in_block_1 + patients_in_block_2)
      expect(facility_group.region.state_region.assigned_patients).to match_array(patients_in_block_1 + patients_in_block_2)
    end
  end

  describe "organization" do
    it "gets the org from the parent org region" do
      org = create(:organization, name: "Test Organization")
      facility_group = create(:facility_group, name: "District XYZ", organization: org, state: "Test State")
      region = facility_group.region
      expect(region.organization).to eq(org)
    end
  end

  describe "behavior" do
    it "sets a valid path" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "District XYZ", organization: org, state: "Test State")
      facility_1 = create(:facility, name: "facility UHC (ZZZ)", state: "Test State", block: "Block22", facility_group: facility_group_1)
      long_name = ("This is a long facility name" * 10)
      facility_2 = create(:facility, name: long_name, block: "Block23", state: "Test State", facility_group: facility_group_1)

      expect(org.region.reload.path).to eq("india.test_organization")
      expect(facility_group_1.region.path).to eq("india.test_organization.test_state.district_xyz")
      expect(facility_1.region.path).to eq("#{facility_group_1.region.path}.#{facility_1.block.downcase}.#{facility_1.region.slug.underscore}")
      expect(facility_2.region.path).to eq("#{facility_group_1.region.path}.#{facility_2.block.downcase}.#{facility_2.region.slug[0..254].underscore}")
    end

    it "can soft delete nodes" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org, state: "State 1")
      facility_group_2 = create(:facility_group, organization: org, state: "State 2")
      _facility_1 = create(:facility, name: "facility1", state: "State 1", facility_group: facility_group_1)
      _facility_2 = create(:facility, name: "facility2", state: "State 2", facility_group: facility_group_2)

      state_2 = Region.find_by!(name: "State 2")
      expect(state_2.children).to_not be_empty
      expect(facility_group_2.reload.region).to_not be_nil

      facility_group_2.discard
      # Ensure that facility group 2's region is discarded with it and no longer in the tree
      expect(facility_group_2.region.path).to be_nil
      expect(facility_group_2.region.parent).to be_nil
      expect(org.region.children.map(&:name)).to contain_exactly("State 1", "State 2")
      expect(state_2.children).to be_empty
    end
  end

  describe "accessible_children" do
    it "only returns children regions that a user has access to" do
      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org, state: "State 1")
      facility_group_2 = create(:facility_group, organization: org, state: "State 1")
      facility_1 = create(:facility, name: "facility1", state: "State 1", facility_group: facility_group_1)
      facility_2 = create(:facility, name: "facility2", facility_group: facility_group_1)
      facility_3 = create(:facility, name: "facility3", state: "State 2", facility_group: facility_group_2)
      block_region = facility_1.region.parent

      facility_report_viewer = create(:admin, :viewer_reports_only, :with_access, full_name: "facility_report_viewer", resource: facility_1)
      district_report_viewer = create(:admin, :viewer_reports_only, :with_access, full_name: "district_report_viewer", resource: facility_group_1)
      other_admin = create(:admin, :manager, :with_access, full_name: "district_report_viewer", resource: facility_group_2)

      expect(facility_group_1.region.accessible_children(facility_report_viewer)).to be_empty
      expect(block_region.accessible_children(facility_report_viewer)).to contain_exactly(facility_1.region)

      expect(facility_group_1.region.accessible_children(district_report_viewer)).to match_array(facility_group_1.region.block_regions)
      expect(facility_group_1.region.accessible_children(district_report_viewer, region_type: :facility)).to match_array([facility_1.region, facility_2.region])
      expect(facility_group_1.region.accessible_children(district_report_viewer, region_type: :facility, access_level: :view_reports)).to match_array([facility_1.region, facility_2.region])
      expect(facility_group_1.region.accessible_children(district_report_viewer, region_type: :facility, access_level: :manage)).to be_empty

      expect(facility_group_1.region.accessible_children(other_admin, region_type: :facility)).to be_empty
      expect(facility_group_1.region.accessible_children(other_admin, region_type: :block)).to be_empty
      expect(facility_group_2.region.accessible_children(other_admin, region_type: :facility)).to match_array(facility_3.region)
      expect(facility_group_2.region.accessible_children(other_admin, region_type: :facility, access_level: :manage)).to match_array(facility_3.region)
    end
  end

  describe "association helper methods" do
    it "generates the appropriate has_one or has_many type methods based on the available region types" do
      facility_group_1 = create(:facility_group, organization: create(:organization), state: "State 1")
      create(:facility, facility_group: facility_group_1, state: "State 1")

      root_region = Region.root
      org_region = Region.organization_regions.first
      state_region = Region.state_regions.first
      district_region = Region.district_regions.first
      block_region = Region.block_regions.first
      facility_region = Region.facility_regions.first

      expect(root_region.root).to eq root_region
      expect(root_region.organization_regions).to contain_exactly org_region
      expect(root_region.state_regions).to contain_exactly state_region
      expect(root_region.district_regions).to contain_exactly district_region
      expect(root_region.block_regions).to contain_exactly block_region
      expect(root_region.facility_regions).to contain_exactly facility_region
      expect { root_region.roots }.to raise_error NoMethodError

      expect(org_region.root).to eq root_region
      expect(org_region.organization_region).to eq org_region
      expect(org_region.state_regions).to contain_exactly state_region
      expect(org_region.district_regions).to contain_exactly district_region
      expect(org_region.block_regions).to contain_exactly block_region
      expect(org_region.facility_regions).to contain_exactly facility_region
      expect { org_region.roots }.to raise_error NoMethodError

      expect(state_region.root).to eq root_region
      expect(state_region.organization_region).to eq org_region
      expect(state_region.state_region).to eq state_region
      expect(state_region.district_regions).to contain_exactly district_region
      expect(state_region.block_regions).to contain_exactly block_region
      expect(state_region.facility_regions).to contain_exactly facility_region
      expect { state_region.roots }.to raise_error NoMethodError
      expect { state_region.organization_regions }.to raise_error NoMethodError

      expect(district_region.root).to eq root_region
      expect(district_region.organization_region).to eq org_region
      expect(district_region.state_region).to eq state_region
      expect(district_region.district_region).to eq district_region
      expect(district_region.block_regions).to contain_exactly block_region
      expect(district_region.facility_regions).to contain_exactly facility_region
      expect { district_region.roots }.to raise_error NoMethodError
      expect { district_region.organization_regions }.to raise_error NoMethodError
      expect { district_region.state_regions }.to raise_error NoMethodError

      expect(block_region.root).to eq root_region
      expect(block_region.organization_region).to eq org_region
      expect(block_region.state_region).to eq state_region
      expect(block_region.district_region).to eq district_region
      expect(block_region.block_region).to eq block_region
      expect(block_region.facility_regions).to contain_exactly facility_region
      expect { block_region.roots }.to raise_error NoMethodError
      expect { block_region.organization_regions }.to raise_error NoMethodError
      expect { block_region.state_regions }.to raise_error NoMethodError
      expect { block_region.district_regions }.to raise_error NoMethodError

      expect(facility_region.root).to eq root_region
      expect(facility_region.organization_region).to eq org_region
      expect(facility_region.state_region).to eq state_region
      expect(facility_region.district_region).to eq district_region
      expect(facility_region.block_region).to eq block_region
      expect(facility_region.facility_region).to eq facility_region
      expect { facility_region.roots }.to raise_error NoMethodError
      expect { facility_region.organization_regions }.to raise_error NoMethodError
      expect { facility_region.state_regions }.to raise_error NoMethodError
      expect { facility_region.district_regions }.to raise_error NoMethodError
      expect { facility_region.block_regions }.to raise_error NoMethodError
    end
  end

  describe "#cohort_analytics" do
    it "invokes the CohortAnalyticsQuery" do
      period = double("Period")
      prev_periods = double("Periods")
      cohort_analytics_query = double("CohortAnalyticsQuery", call: "result")
      region = Region.new(name: "foo", path: "foo")

      allow(CohortAnalyticsQuery).to receive(:new)
        .with(region, period: period, prev_periods: prev_periods)
        .and_return(cohort_analytics_query)

      expect(region.cohort_analytics(period: period, prev_periods: prev_periods)).to eq("result")
    end
  end

  describe "#dashboard_analytics" do
    context "for facility regions" do
      it "invokes the CohortAnalyticsQuery" do
        period = double("Period")
        prev_periods = double("Periods")
        facility_analytics_query = double("FacilityAnalyticsQuery", call: "result")

        region = Region.new(name: "foo", path: "foo", region_type: "facility")

        allow(FacilityAnalyticsQuery).to receive(:new)
          .with(region, period, prev_periods, include_current_period: false)
          .and_return(facility_analytics_query)

        result = region.dashboard_analytics(
          period: period,
          prev_periods: prev_periods,
          include_current_period: false
        )

        expect(result).to eq("result")
      end
    end

    context "for non-facility regions" do
      it "invokes the CohortAnalyticsQuery" do
        period = double("Period")
        prev_periods = double("Periods")
        district_analytics_query = double("DistrictAnalyticsQuery", call: "result")

        region = Region.new(name: "foo", path: "foo", region_type: "district")

        allow(DistrictAnalyticsQuery).to receive(:new)
          .with(region, period, prev_periods, include_current_period: false)
          .and_return(district_analytics_query)

        result = region.dashboard_analytics(
          period: period,
          prev_periods: prev_periods,
          include_current_period: false
        )

        expect(result).to eq("result")
      end
    end
  end

  describe "#syncable_patients" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization, state: "Maharashtra") }
    let!(:facility_1) { create(:facility, block: "M1", facility_group: facility_group) }
    let!(:facility_2) { create(:facility, block: "M2", facility_group: facility_group) }
    let!(:facility_3) { create(:facility, block: "M2", facility_group: facility_group) }
    let!(:facility_4) { create(:facility, block: "P1", facility_group: facility_group) }

    it "accounts for patients registered in the facility of the region" do
      patient_from_f1 = create(:patient, registration_facility: facility_1)
      patient_from_f2 = create(:patient, registration_facility: facility_2)
      patient_from_f3 = create(:patient, registration_facility: facility_3)
      patient_from_f4 = create(:patient, registration_facility: facility_4)

      expect(Region.root.syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_from_f4)

      expect(Region.organization_regions.find_by(source: organization).syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_from_f4)

      expect(organization.region.state_regions.find_by(name: "Maharashtra").syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_from_f4)

      expect(organization.region.district_regions.find_by(source: facility_group).syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_from_f4)

      expect(organization.region.block_regions.find_by(name: "M1").syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.block_regions.find_by(name: "M2").syncable_patients)
        .to contain_exactly(patient_from_f2, patient_from_f3)
      expect(organization.region.block_regions.find_by(name: "P1").syncable_patients)
        .to contain_exactly(patient_from_f4)

      expect(organization.region.facility_regions.find_by(source: facility_1).syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.facility_regions.find_by(source: facility_2).syncable_patients)
        .to contain_exactly(patient_from_f2)
      expect(organization.region.facility_regions.find_by(source: facility_3).syncable_patients)
        .to contain_exactly(patient_from_f3)
      expect(organization.region.facility_regions.find_by(source: facility_4).syncable_patients)
        .to contain_exactly(patient_from_f4)
    end

    it "accounts for patients assigned in the facility of the region" do
      patient_from_f1 = create(:patient, registration_facility: facility_1)
      patient_from_f2 = create(:patient, assigned_facility: facility_2)
      patient_from_f3 = create(:patient, assigned_facility: facility_3)
      patient_elsewhere = create(:patient)

      expect(Region.root.syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_elsewhere)

      expect(Region.organization_regions.find_by(source: organization).syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.state_regions.find_by(name: "Maharashtra").syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.district_regions.find_by(source: facility_group).syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.block_regions.find_by(name: "M1").syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.block_regions.find_by(name: "M2").syncable_patients)
        .to contain_exactly(patient_from_f2, patient_from_f3)
      expect(organization.region.block_regions.find_by(name: "P1").syncable_patients)
        .to be_empty

      expect(organization.region.facility_regions.find_by(source: facility_1).syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.facility_regions.find_by(source: facility_2).syncable_patients)
        .to be_empty
      expect(organization.region.facility_regions.find_by(source: facility_3).syncable_patients)
        .to be_empty
      expect(organization.region.facility_regions.find_by(source: facility_4).syncable_patients)
        .to be_empty
    end

    it "accounts for patients who have an appointment in the facility of the region" do
      patient_from_f1 = create(:patient, registration_facility: facility_1)
      patient_from_f2 = create(:patient)
      create(:appointment, patient: patient_from_f2, facility: facility_2)
      patient_from_f3 = create(:patient)
      create(:appointment, patient: patient_from_f3, facility: facility_3)
      patient_elsewhere = create(:patient)

      expect(Region.root.syncable_patients)
        .to contain_exactly(patient_from_f1, patient_from_f2, patient_from_f3, patient_elsewhere)

      expect(Region.organization_regions.find_by(source: organization).syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.state_regions.find_by(name: "Maharashtra").syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.district_regions.find_by(source: facility_group).syncable_patients)
        .to contain_exactly(patient_from_f1)

      expect(organization.region.block_regions.find_by(name: "M1").syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.block_regions.find_by(name: "M2").syncable_patients)
        .to contain_exactly(patient_from_f2, patient_from_f3)
      expect(organization.region.block_regions.find_by(name: "P1").syncable_patients)
        .to be_empty

      expect(organization.region.facility_regions.find_by(source: facility_1).syncable_patients)
        .to contain_exactly(patient_from_f1)
      expect(organization.region.facility_regions.find_by(source: facility_2).syncable_patients)
        .to be_empty
      expect(organization.region.facility_regions.find_by(source: facility_3).syncable_patients)
        .to be_empty
      expect(organization.region.facility_regions.find_by(source: facility_4).syncable_patients)
        .to be_empty
    end
  end

  describe "#diabetes_management_enabled?" do
    let(:facility_1) { create(:facility, enable_diabetes_management: true) }
    let(:facility_2) { create(:facility, enable_diabetes_management: false) }
    let(:facility_3) { create(:facility, enable_diabetes_management: false) }

    let(:enabled_state_region) { create(:region, region_type: :state, reparent_to: Region.root) }
    let(:enabled_district_region) { create(:region, region_type: :district, reparent_to: enabled_state_region) }
    let(:enabled_block_region) { create(:region, region_type: :block, reparent_to: enabled_district_region) }

    let(:disabled_state_region) { create(:region, region_type: :state, reparent_to: Region.root) }
    let(:disabled_district_region) { create(:region, region_type: :district, reparent_to: enabled_state_region) }
    let(:disabled_block_region) { create(:region, region_type: :block, reparent_to: enabled_district_region) }

    context "region is a facility" do
      it "returns true if enable_diabetes_management is set to true for the facility" do
        facility_region = create(:region, region_type: :facility, source: facility_1, reparent_to: enabled_block_region)
        expect(facility_region.diabetes_management_enabled?).to eq(true)
      end

      it "returns false if enable_diabetes_management is set to false for the facility" do
        facility_region = create(:region, region_type: :facility, source: facility_2, reparent_to: enabled_block_region)
        expect(facility_region.diabetes_management_enabled?).to eq(false)
      end
    end

    context "region contains many facilities" do
      it "returns true if any of its facilities has enabled_diabetes_management set to  true" do
        create(:region, region_type: :facility, source: facility_1, reparent_to: enabled_block_region)
        create(:region, region_type: :facility, source: facility_2, reparent_to: enabled_block_region)

        expect(enabled_state_region.diabetes_management_enabled?).to eq(true)
        expect(enabled_district_region.diabetes_management_enabled?).to eq(true)
        expect(enabled_block_region.diabetes_management_enabled?).to eq(true)
      end

      it "returns false only if all of its facilities has enabled_diabetes_management set to false" do
        create(:region, region_type: :facility, source: facility_2, reparent_to: disabled_block_region)
        create(:region, region_type: :facility, source: facility_3, reparent_to: disabled_block_region)

        expect(disabled_state_region.diabetes_management_enabled?).to eq(false)
        expect(disabled_district_region.diabetes_management_enabled?).to eq(false)
        expect(disabled_block_region.diabetes_management_enabled?).to eq(false)
      end
    end
  end

  context "flipperable" do
    it "has a flipper_id" do
      region = create(:region, reparent_to: Region.root)

      expect(region.flipper_id).to eq("Region;#{region.id}")
    end

    describe "#feature_enabled?" do
      it "returns true when feature is enabled" do
        region = create(:region, reparent_to: Region.root)
        Flipper.enable(:a_flag, region)

        expect(region.feature_enabled?(:a_flag)).to be true
      end

      it "returns false when feature is disabled" do
        region = create(:region, reparent_to: Region.root)
        expect(region.feature_enabled?(:a_flag)).to be false
      end
    end
  end
end
