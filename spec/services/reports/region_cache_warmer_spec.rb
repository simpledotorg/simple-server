require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  let(:facility_group) { create(:facility_group) }
  let(:user) { create(:user, organization: facility_group.organization) }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:august_1_2020) { Time.parse("August 1, 2020 00:00:00+00:00") }

  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)

    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  around do |ex|
    with_reporting_time_zone { ex.run }
  end

  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::Repository).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "sets bust cache to false before running queries" do
    allow(RequestStore.store).to receive(:[]=)
    warmer = Reports::RegionCacheWarmer.new
    expect(RequestStore.store).to receive(:[]=).with(:bust_cache, true).ordered
    expect(warmer).to receive(:warm_caches).once.ordered
    expect(RequestStore.store).to receive(:[]=).with(:bust_cache, false).ordered

    warmer.call
  end

  it "new data is cached with every run of the cache warmer" do
    facility_1 = create(:facility, facility_group: facility_group)
    slug = facility_1.region.slug
    patient = Timecop.freeze(june_1_2020) do
      user = create(:user, organization: facility_group.organization)
      create(:patient, registration_facility: facility_1, registration_user: user)
    end
    Timecop.freeze(august_1_2020) do
      create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, user: user)
    end

    Timecop.freeze("September 1st 2020 00:04:00+00:00:00") do
      RefreshReportingViews.call
      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current.downto(6))
      expect(repo.cumulative_assigned_patients[slug][Period.current]).to eq(1)
      expect(repo.uncontrolled[slug][Period.current]).to eq(0)
      expect(repo.controlled[slug][Period.current]).to eq(1)
    end
    Timecop.freeze("September 2st 2020 00:04:00+00:00:00") do
      create(:patient, registration_facility: facility_1, registration_user: user)
      create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, user: user)
      RefreshReportingViews.call
      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current.downto(6))
      expect(repo.cumulative_assigned_patients[slug][Period.current]).to eq(2)
      expect(repo.uncontrolled[slug][Period.current]).to eq(1)
      expect(repo.controlled[slug][Period.current]).to eq(0)
    end
  end

  it "completes successfully" do
    facility = create(:facility, facility_group: facility_group)
    create(:patient, registration_facility: facility, registration_user: user)
    RefreshReportingViews.call
    Reports::RegionCacheWarmer.call
  end

  context "warm_repository_cache" do
    it "caches all non root/org regions in the v2 schema" do
      facility_1 = create(:facility, facility_group: facility_group)
      user = create(:user, organization: facility_group.organization)
      patient = create(:patient, registration_facility: facility_1, recorded_at: 2.months.ago, registration_user: user)
      create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago)

      RefreshReportingViews.call

      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current)
      expect(repo.schema).to receive(:controlled).never # ensure the cache is hit and we don't retrieve counts again for the rate calc
      repo.controlled_rates
      repo.controlled_rates(with_ltfu: true)
    end

    it "caches all the result of repository methods" do
      facility = create(:facility, facility_group: facility_group)
      user = create(:user, organization: facility_group.organization)
      patient = create(:patient, registration_facility: facility, recorded_at: 2.months.ago, registration_user: user)
      create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 15.days.ago)
      create(:blood_sugar_with_encounter, :bs_below_200, facility: facility, patient: patient, recorded_at: 15.days.ago)

      cache_keys = Rails.cache.instance_variable_get(:@data).keys
      expect(cache_keys).to be_empty

      RefreshReportingViews.call

      described_class.call
      Reports::Repository.new(facility, periods: Period.current)
      cache_keys = Rails.cache.instance_variable_get(:@data).keys

      expect(cache_keys).to_not be_empty

      expected_keys_in_cache = [
        /bp_measures_by_user/,
        /blood_sugar_measures_by_user/,
        /monthly_registrations_by_user\/group_by\/registration_user_id\/period_type\/month\/diagnosis\/hypertension/,
        /monthly_registrations_by_user\/group_by\/registration_user_id\/period_type\/month\/diagnosis\/diabetes/,
        /monthly_registrations_by_gender/,
        /controlled_by_gender/,
        /overdue_calls_by_user/
      ]

      expected_keys_in_cache.each do |expected_key|
        expect(cache_keys.any? { |key| key.match(expected_key) }).to eq true
      end
    end
  end
end
