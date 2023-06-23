require "rails_helper"

RSpec.describe Reports::RegionSummary, {type: :model, reporting_spec: true} do
  using StringToPeriod

  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:user_2) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { create(:facility, name: "facility-1", facility_group: facility_group_1) }
  let(:facility_2) { create(:facility, name: "facility-2", facility_group: facility_group_1) }
  let(:jan_2019) { Time.zone.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.zone.parse("January 1st, 2020 00:00:00+00:00") }
  let(:mar_2020) { Time.zone.parse("March 1st, 2020 00:00:00+00:00") }

  around do |example|
    with_reporting_time_zone { example.run }
  end

  context "API contract" do
    it "regions with no patient data an empty hash" do
      refresh_views
      result = described_class.call(facility_group_1)
      expect(result).to eq("facility_group_1" => {})
      expect(result["facility_group_1"][jan_2020.to_period]).to be_nil
    end

    # This spec illustrates that the data returned relies on current_date in reporting_months, regardless of what
    # we do with freezing time in Ruby-land.
    it "returns data from first patient record to PostgreSQL current_date, regardless of Ruby frozen time" do
      _facility_1_patients = create(:patient, recorded_at: jan_2020, assigned_facility: facility_1, registration_user: user)
      results = Timecop.freeze(mar_2020) do
        refresh_views
        described_class.call(facility_1)
      end
      expected_range = (jan_2020.to_period..Time.current.to_period)
      expect(results[facility_1.region.slug].keys).to eq(expected_range.entries)
    end

    context "explicit range provided" do
      it "returns data only for periods with patient data" do
        _facility_1_patients = create(:patient, recorded_at: jan_2020, assigned_facility: facility_1, registration_user: user)
        explicit_range = (jan_2019.to_period..mar_2020.to_period)
        expected_range = (jan_2020.to_period..mar_2020.to_period)
        results = Timecop.freeze(mar_2020) do
          refresh_views
          described_class.call([facility_1, facility_2], range: explicit_range)
        end
        expect(results[facility_1.region.slug].keys).to eq(expected_range.entries)
      end
    end

    it "raises error if passed regions of different types" do
      expect { described_class.call([facility_group_1, create(:facility)]) }.to raise_error(ArgumentError, /must be called with regions of the same region_type/)
    end

    it "returns a hash of hashes containing key/value pairs of attributes for each period" do
      registration_time, now = 3.months.ago, Time.current
      _facility_1_patients = create_list(:patient, 2, full_name: "controlled", recorded_at: registration_time, assigned_facility: facility_1, registration_user: user)
      results = Timecop.freeze(now) do
        refresh_views
        described_class.call(facility_1)
      end
      # Intentionally non-DRY here because we want to double check and easily see what fields are returned in our hashes
      expected_keys = %i[
        adjusted_controlled_under_care
        adjusted_missed_visit_lost_to_follow_up
        adjusted_missed_visit_under_care
        adjusted_missed_visit_under_care_with_lost_to_follow_up
        adjusted_patients_under_care
        adjusted_uncontrolled_under_care
        adjusted_visited_no_bp_lost_to_follow_up
        adjusted_visited_no_bp_under_care
        adjusted_visited_no_bp_under_care_with_lost_to_follow_up
        cumulative_assigned_patients
        cumulative_registrations
        cumulative_diabetes_registrations
        cumulative_hypertension_and_diabetes_registrations
        facility_region_slug
        lost_to_follow_up
        diabetes_lost_to_follow_up
        under_care
        diabetes_under_care
        monthly_registrations
        monthly_diabetes_registrations
        monthly_hypertension_and_diabetes_registrations
        month_date
        monthly_overdue_calls
        monthly_follow_ups
        monthly_diabetes_follow_ups
        total_appts_scheduled
        appts_scheduled_0_to_14_days
        appts_scheduled_15_to_31_days
        appts_scheduled_32_to_62_days
        appts_scheduled_more_than_62_days
        cumulative_assigned_diabetic_patients
        adjusted_diabetes_patients_under_care
        adjusted_bs_below_200_under_care
        adjusted_random_bs_below_200_under_care
        adjusted_post_prandial_bs_below_200_under_care
        adjusted_fasting_bs_below_200_under_care
        adjusted_hba1c_bs_below_200_under_care
        adjusted_visited_no_bs_under_care
        adjusted_bs_missed_visit_under_care
        adjusted_bs_missed_visit_lost_to_follow_up
        adjusted_bs_200_to_300_under_care
        adjusted_random_bs_200_to_300_under_care
        adjusted_post_prandial_bs_200_to_300_under_care
        adjusted_fasting_bs_200_to_300_under_care
        adjusted_hba1c_bs_200_to_300_under_care
        adjusted_bs_over_300_under_care
        adjusted_random_bs_over_300_under_care
        adjusted_post_prandial_bs_over_300_under_care
        adjusted_fasting_bs_over_300_under_care
        adjusted_hba1c_bs_over_300_under_care
        adjusted_bs_missed_visit_under_care_with_lost_to_follow_up
        diabetes_total_appts_scheduled
        diabetes_appts_scheduled_0_to_14_days
        diabetes_appts_scheduled_15_to_31_days
        diabetes_appts_scheduled_32_to_62_days
        diabetes_appts_scheduled_more_than_62_days
        diabetes_dead
        dead
        overdue_patients
        contactable_overdue_patients
        patients_called
        contactable_patients_called
        patients_called_with_result_agreed_to_visit
        patients_called_with_result_remind_to_call_later
        patients_called_with_result_removed_from_list
        contactable_patients_called_with_result_agreed_to_visit
        contactable_patients_called_with_result_remind_to_call_later
        contactable_patients_called_with_result_removed_from_list
        patients_returned_after_call
        patients_returned_with_result_agreed_to_visit
        patients_returned_with_result_remind_to_call_later
        patients_returned_with_result_removed_from_list
        contactable_patients_returned_after_call
        contactable_patients_returned_with_result_agreed_to_visit
        contactable_patients_returned_with_result_remind_to_call_later
        contactable_patients_returned_with_result_removed_from_list
      ].map(&:to_s)
      (3.months.ago.to_period..now.to_period).each do |period|
        expect(results[facility_1.region.slug][period].keys).to match_array(expected_keys)
        counts = results[facility_1.region.slug][period].except("facility_region_slug", "month_date")
        expect(counts.values).to all(be_an(Integer))
      end
    end
  end

  context "with explicit range" do
    it "does not return data for periods with no patients" do
      facility_1 = create(:facility, name: "facility opened jan 2020", facility_group: facility_group_1)
      facility_2 = create(:facility, name: "facility opened mar 2020", facility_group: facility_group_1)
      _facility_1_patients = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, assigned_facility: facility_1, registration_user: user)
      _facility_2_patients = create_list(:patient, 2, full_name: "controlled", recorded_at: mar_2020, assigned_facility: facility_2, registration_user: user)

      Timecop.freeze("June 1st 2021") do
        refresh_views
        range = (Period.current.advance(months: -24)..Period.current)
        facility_result = described_class.call([facility_1, facility_2], range: range)
        facility_1_periods = facility_result["facility-opened-jan-2020"].keys
        expect(facility_1_periods.first).to eq(jan_2020.to_period)
        facility_2_periods = facility_result["facility-opened-mar-2020"].keys
        expect(facility_2_periods.first).to eq(mar_2020.to_period)

        district_result = described_class.call(facility_group_1, range: range)
        expect(district_result["facility_group_1"].keys.first).to eq(jan_2020.to_period)
      end
    end
  end

  it "returns correct data for regions" do
    skip "needs investigation from @rsanheim"
    facility_1, facility_2 = *FactoryBot.create_list(:facility, 2, block: "block-1", facility_group: facility_group_1).sort_by(&:slug)
    facility_3 = FactoryBot.create(:facility, block: "block-2", facility_group: facility_group_1)
    facilities = [facility_1, facility_2, facility_3]
    district_region = facility_group_1.region
    block_regions = facilities.map(&:block_region)

    facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      (facility_1_controlled << facility_2_controlled).map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
      end
      facility_1_uncontrolled.map do |patient|
        create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago)
      end
      refresh_views
    end

    result = described_class.call(facilities, range: jan_2020)
    expect(result[facility_1.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 2)
    expect(result[facility_2.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 1)
    expect(result[facility_3.slug][jan_2020.to_period]).to be_nil

    district_data = described_class.call(district_region, range: jan_2020)
    expect(district_data["facility_group_1"][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 3)

    block_data = described_class.call(block_regions)
    expect(block_data["block-1"]["December 2020".to_period]).to include("adjusted_controlled_under_care" => 0)
    expect(block_data["block-1"]["January 2020".to_period]).to include("adjusted_controlled_under_care" => 3)
    expect(block_data["block-2"]["January 2020".to_period]).to be_nil
  end

  it "returns follow ups" do
    facility_1 = FactoryBot.create(:facility, name: "facility 1", block: "block-1", facility_group: facility_group_1)
    facility_2 = FactoryBot.create(:facility, name: "facility 2", block: "block-1", facility_group: facility_group_1)
    htn_patients_with_one_follow_up_every_month = create_list(:patient, 2, full_name: "facility 1 patient with HTN", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    htn_patients_with_many_follow_ups_in_one_month = create_list(:patient, 2, full_name: "facility 2 patient with HTN", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
    diabetes_patients = create_list(:patient, 2, :diabetes, full_name: "patient with diabetes", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

    range = ("October 1st 2019".to_period.."March 1st 2020".to_period)

    range.each do |period|
      diabetes_patients.each { |p| create(:blood_sugar, facility: facility_1, patient: p, recorded_at: period.to_date, user: user) }
      htn_patients_with_one_follow_up_every_month.each { |p| create(:bp_with_encounter, :under_control, facility: facility_1, patient: p, recorded_at: period.to_date, user: user) }
    end
    htn_patients_with_many_follow_ups_in_one_month.each do |p| # all the below should count as _one_ follow up for the month
      create(:appointment, recorded_at: jan_2020, patient: p, facility: facility_1, user: user)
      create(:appointment, recorded_at: jan_2020, patient: p, facility: facility_1, user: user_2)
      create(:blood_sugar_with_encounter, recorded_at: jan_2020.advance(days: 15), patient: p, facility: facility_1, user: user)
      create(:bp_with_encounter, recorded_at: jan_2020.advance(days: 13), patient: p, facility: facility_2, user: user)
      create(:prescription_drug, recorded_at: jan_2020.advance(days: 10), patient: p, facility: facility_1, user: user)
    end

    refresh_views

    expected_facility_1_follow_ups = {
      "October 1st 2019" => {"monthly_follow_ups" => 2},
      "November 1st 2019" => {"monthly_follow_ups" => 2},
      "December 1st 2019" => {"monthly_follow_ups" => 2},
      "January 1st 2020" => {"monthly_follow_ups" => 4},
      "February 1st 2020" => {"monthly_follow_ups" => 2},
      "March 1st 2020" => {"monthly_follow_ups" => 2}
    }.transform_keys!(&:to_period)
    facility_1_results = described_class.call(facility_1, range: range)[facility_1.region.slug].transform_values { |values| values.slice("monthly_follow_ups") }
    expect(facility_1_results).to eq(expected_facility_1_follow_ups)

    expected_facility_2_follow_ups = {
      "October 1st 2019" => {"monthly_follow_ups" => 0},
      "November 1st 2019" => {"monthly_follow_ups" => 0},
      "December 1st 2019" => {"monthly_follow_ups" => 0},
      "January 1st 2020" => {"monthly_follow_ups" => 2},
      "February 1st 2020" => {"monthly_follow_ups" => 0},
      "March 1st 2020" => {"monthly_follow_ups" => 0}
    }.transform_keys!(&:to_period)
    facility_2_results = described_class.call([facility_2, facility_1], range: range)[facility_2.region.slug].transform_values { |values| values.slice("monthly_follow_ups") }
    expect(facility_2_results).to eq(expected_facility_2_follow_ups)

    district_results = described_class.call(facility_group_1, range: range)[facility_group_1.region.slug].transform_values { |values| values.slice("monthly_follow_ups") }
    expected_district_follow_ups = {
      "October 1st 2019" => {"monthly_follow_ups" => 2},
      "November 1st 2019" => {"monthly_follow_ups" => 2},
      "December 1st 2019" => {"monthly_follow_ups" => 2},
      "January 1st 2020" => {"monthly_follow_ups" => 6},
      "February 1st 2020" => {"monthly_follow_ups" => 2},
      "March 1st 2020" => {"monthly_follow_ups" => 2}
    }.transform_keys!(&:to_period)
    expect(district_results).to eq(expected_district_follow_ups)
  end

  it "sums LTFU and under care counts for missed visits and visited no BP" do
    facility_1 = FactoryBot.create_list(:facility, 1, facility_group: facility_group_1).first
    slug = facility_1.region.slug
    # Patient registers Jan 2019 and has a visit with no BP Jan 2020...so they have a
    # visit w/ no BP. Since an appointment is created in Jan 2020, the patient is under care from Jan 2020 through Dec 2020
    # The patient becomes lost to follow up in Jan 2021
    visit_with_no_bp_and_ltfu = create(:patient, full_name: "visit_with_no_bp_and_ltfu", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    create(:appointment, patient: visit_with_no_bp_and_ltfu, recorded_at: jan_2020, facility: facility_1, user: user)

    result = Timecop.freeze("October 1st 2021") do
      refresh_views
      described_class.call(facility_1)
    end
    facility_results = result[slug]
    (("January 2019".to_period)..("March 2019".to_period)).each do |period|
      expect(facility_results[period]["cumulative_assigned_patients"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care"]).to eq(0)
      expect(facility_results[period]["adjusted_missed_visit_under_care_with_lost_to_follow_up"]).to eq(0)
    end
    (("April 2019".to_period)..("December 2019".to_period)).each do |period|
      expect(facility_results[period]["cumulative_assigned_patients"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care_with_lost_to_follow_up"]).to eq(1)
    end
    (("January 2020".to_period)..("March 2020".to_period)).each do |period|
      expect(facility_results[period]["cumulative_assigned_patients"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care"]).to eq(0)
      expect(facility_results[period]["adjusted_missed_visit_under_care_with_lost_to_follow_up"]).to eq(0)
      expect(facility_results[period]["adjusted_visited_no_bp_lost_to_follow_up"]).to eq(0)
      expect(facility_results[period]["lost_to_follow_up"]).to eq(0)
    end
    (("April 2020".to_period)..("December 2020".to_period)).each do |period|
      expect(facility_results[period]["cumulative_assigned_patients"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care_with_lost_to_follow_up"]).to eq(1)
      expect(facility_results[period]["adjusted_visited_no_bp_lost_to_follow_up"]).to eq(0)
      expect(facility_results[period]["lost_to_follow_up"]).to eq(0)
    end
    (("Jan 2021".to_period)..("October 2021".to_period)).each do |period|
      expect(facility_results[period]["cumulative_assigned_patients"]).to eq(1)
      expect(facility_results[period]["adjusted_missed_visit_under_care"]).to eq(0)
      expect(facility_results[period]["adjusted_missed_visit_under_care_with_lost_to_follow_up"]).to eq(1)
      expect(facility_results[period]["adjusted_visited_no_bp_lost_to_follow_up"]).to eq(0)
      expect(facility_results[period]["lost_to_follow_up"]).to eq(1)
    end
  end

  context "diabetes" do
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:facility_1) { district_with_facilities[:facility_1] }
    let(:facility_2) { district_with_facilities[:facility_2] }
    let(:period) { jan_2020..mar_2020 }

    before :each do
      facility_1.update(enable_diabetes_management: true)
      facility_2.update(enable_diabetes_management: true)
    end

    it "returns the adjusted count of patients with bs <200 in a region" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
        expect(facility_1_results[period]).to include({
          "adjusted_bs_below_200_under_care" => 0,
          "adjusted_random_bs_below_200_under_care" => 0,
          "adjusted_post_prandial_bs_below_200_under_care" => 0,
          "adjusted_fasting_bs_below_200_under_care" => 0,
          "adjusted_hba1c_bs_below_200_under_care" => 0
        })
        expect(facility_2_results[period]).to include({
          "adjusted_bs_below_200_under_care" => 0,
          "adjusted_random_bs_below_200_under_care" => 0,
          "adjusted_post_prandial_bs_below_200_under_care" => 0,
          "adjusted_fasting_bs_below_200_under_care" => 0,
          "adjusted_hba1c_bs_below_200_under_care" => 0
        })
        expect(region_results[period]).to include({
          "adjusted_bs_below_200_under_care" => 0,
          "adjusted_random_bs_below_200_under_care" => 0,
          "adjusted_post_prandial_bs_below_200_under_care" => 0,
          "adjusted_fasting_bs_below_200_under_care" => 0,
          "adjusted_hba1c_bs_below_200_under_care" => 0
        })
      end

      expect(facility_1_results["Mar 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 2,
        "adjusted_random_bs_below_200_under_care" => 0,
        "adjusted_post_prandial_bs_below_200_under_care" => 1,
        "adjusted_fasting_bs_below_200_under_care" => 1,
        "adjusted_hba1c_bs_below_200_under_care" => 0
      })
      expect(facility_2_results["Mar 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 2,
        "adjusted_random_bs_below_200_under_care" => 0,
        "adjusted_post_prandial_bs_below_200_under_care" => 1,
        "adjusted_fasting_bs_below_200_under_care" => 1,
        "adjusted_hba1c_bs_below_200_under_care" => 0
      })
      expect(region_results["Mar 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 4,
        "adjusted_random_bs_below_200_under_care" => 0,
        "adjusted_post_prandial_bs_below_200_under_care" => 2,
        "adjusted_fasting_bs_below_200_under_care" => 2,
        "adjusted_hba1c_bs_below_200_under_care" => 0
      })

      expect(facility_1_results["Apr 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 4,
        "adjusted_random_bs_below_200_under_care" => 1,
        "adjusted_post_prandial_bs_below_200_under_care" => 1,
        "adjusted_fasting_bs_below_200_under_care" => 1,
        "adjusted_hba1c_bs_below_200_under_care" => 1
      })
      expect(facility_2_results["Apr 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 3,
        "adjusted_random_bs_below_200_under_care" => 1,
        "adjusted_post_prandial_bs_below_200_under_care" => 1,
        "adjusted_fasting_bs_below_200_under_care" => 1,
        "adjusted_hba1c_bs_below_200_under_care" => 0
      })
      expect(region_results["Apr 2020".to_period]).to include({
        "adjusted_bs_below_200_under_care" => 7,
        "adjusted_random_bs_below_200_under_care" => 2,
        "adjusted_post_prandial_bs_below_200_under_care" => 2,
        "adjusted_fasting_bs_below_200_under_care" => 2,
        "adjusted_hba1c_bs_below_200_under_care" => 1
      })
    end

    it "returns the adjusted count of patients with bs between 200 to 300 in a region" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_200_to_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :hba1c, :bs_200_to_300, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_200_to_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
        expect(facility_1_results[period]).to include({
          "adjusted_bs_200_to_300_under_care" => 0
        })
        expect(facility_2_results[period]).to include({
          "adjusted_bs_200_to_300_under_care" => 0
        })
        expect(region_results[period]).to include({
          "adjusted_bs_200_to_300_under_care" => 0
        })
      end

      expect(facility_1_results["Mar 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 2
      })
      expect(facility_2_results["Mar 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 2
      })
      expect(region_results["Mar 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 4
      })

      expect(facility_1_results["Apr 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 4
      })
      expect(facility_2_results["Apr 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 3
      })
      expect(region_results["Apr 2020".to_period]).to include({
        "adjusted_bs_200_to_300_under_care" => 7
      })
    end

    it "returns the adjusted count of patients with bs over 300 in a region" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_over_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_over_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
        expect(facility_1_results[period]).to include({
          "adjusted_bs_over_300_under_care" => 0
        })
        expect(facility_2_results[period]).to include({
          "adjusted_bs_over_300_under_care" => 0
        })
        expect(region_results[period]).to include({
          "adjusted_bs_over_300_under_care" => 0
        })
      end

      expect(facility_1_results["Mar 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 2
      })
      expect(facility_2_results["Mar 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 2
      })
      expect(region_results["Mar 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 4
      })

      expect(facility_1_results["Apr 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 4
      })
      expect(facility_2_results["Apr 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 3
      })
      expect(region_results["Apr 2020".to_period]).to include({
        "adjusted_bs_over_300_under_care" => 7
      })
    end

    it "returns the adjusted count of patients with missed visits in a region" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Mar 2019".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
        expect(facility_2_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
        expect(region_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
      end

      (("Apr 2019".to_period)..("Dec 2019".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 4
        expect(facility_2_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 3
        expect(region_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 7
      end

      (("Jan 2020".to_period)..("May 2020".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
        expect(facility_2_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
        expect(region_results[period]["adjusted_bs_missed_visit_under_care"]).to eq 0
      end

      expect(facility_1_results["Jun 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 2
      expect(facility_2_results["Jun 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 2
      expect(region_results["Jun 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 4

      expect(facility_1_results["Aug 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 4
      expect(facility_2_results["Aug 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 3
      expect(region_results["Aug 2020".to_period]["adjusted_bs_missed_visit_under_care"]).to eq 7
    end

    it "returns the adjusted count of patients with lost to follow up in a region" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Dec 2019".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0
        expect(facility_2_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0
        expect(region_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0
      end

      (("Jan 2020".to_period)..("Feb 2020".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 4
        expect(facility_2_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 3
        expect(region_results[period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 7
      end

      expect(facility_1_results["Mar 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 2
      expect(facility_2_results["Mar 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 1
      expect(region_results["Mar 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 3

      expect(facility_1_results["Apr 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0
      expect(facility_2_results["Apr 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0
      expect(region_results["Apr 2020".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 0

      expect(facility_1_results["Mar 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 2
      expect(facility_2_results["Mar 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 2
      expect(region_results["Mar 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 4

      expect(facility_1_results["Apr 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 4
      expect(facility_2_results["Apr 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 3
      expect(region_results["Apr 2021".to_period]["adjusted_bs_missed_visit_lost_to_follow_up"]).to eq 7
    end

    it "returns the adjusted count of patients who visited but did not have a BS measurement" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_pressure, :with_encounter, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:appointment, patient: facility_1_patients.second, facility: facility_1, device_created_at: jan_2020 + 2.months)
      create(:prescription_drug, patient: facility_1_patients.third, facility: facility_1, device_created_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_pressure, :with_encounter, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:appointment, patient: facility_2_patients.second, facility: facility_2, device_created_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]
      (("Jan 2019".to_period)..("Feb 2019".to_period)).each do |period|
        expect(facility_1_results[period]["adjusted_visited_no_bs_under_care"]).to eq 0
        expect(facility_2_results[period]["adjusted_visited_no_bs_under_care"]).to eq 0
        expect(region_results[period]["adjusted_visited_no_bs_under_care"]).to eq 0
      end

      expect(facility_1_results["Mar 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 2
      expect(facility_2_results["Mar 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 1
      expect(region_results["Mar 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 3

      expect(facility_1_results["Apr 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 3
      expect(facility_2_results["Apr 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 2
      expect(region_results["Apr 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 5

      expect(facility_1_results["Jun 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 1
      expect(facility_2_results["Jun 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 1
      expect(region_results["Jun 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 2

      expect(facility_1_results["Jul 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 0
      expect(facility_2_results["Jul 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 0
      expect(region_results["Jul 2020".to_period]["adjusted_visited_no_bs_under_care"]).to eq 0
    end

    it "returns the number of cumulative diabetes registrations" do
      create_list(:patient, 4, :diabetes, registration_facility: facility_1, recorded_at: jan_2019)
      create_list(:patient, 3, :diabetes, registration_facility: facility_2, recorded_at: jan_2019)

      create_list(:patient, 4, :diabetes, registration_facility: facility_1, recorded_at: jan_2019 + 3.months)
      create_list(:patient, 3, :diabetes, registration_facility: facility_2, recorded_at: jan_2019 + 3.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      (("Jan 2019".to_period)..("Mar 2019".to_period)).each do |period|
        expect(facility_1_results[period]["cumulative_diabetes_registrations"]).to eq 4
        expect(facility_2_results[period]["cumulative_diabetes_registrations"]).to eq 3
        expect(region_results[period]["cumulative_diabetes_registrations"]).to eq 7
      end

      (("Apr 2019".to_period)..("Mar 2020".to_period)).each do |period|
        expect(facility_1_results[period]["cumulative_diabetes_registrations"]).to eq 8
        expect(facility_2_results[period]["cumulative_diabetes_registrations"]).to eq 6
        expect(region_results[period]["cumulative_diabetes_registrations"]).to eq 14
      end
    end

    it "returns the number of monthly diabetes registrations" do
      create_list(:patient, 4, :diabetes, registration_facility: facility_1, recorded_at: jan_2019)
      create_list(:patient, 3, :diabetes, registration_facility: facility_2, recorded_at: jan_2019)

      create_list(:patient, 5, :diabetes, registration_facility: facility_1, recorded_at: jan_2019 + 3.months)
      create_list(:patient, 6, :diabetes, registration_facility: facility_2, recorded_at: jan_2019 + 3.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results["Jan 2019".to_period]["monthly_diabetes_registrations"]).to eq 4
      expect(facility_2_results["Jan 2019".to_period]["monthly_diabetes_registrations"]).to eq 3
      expect(region_results["Jan 2019".to_period]["monthly_diabetes_registrations"]).to eq 7

      (("Feb 2019".to_period)..("Mar 2019".to_period)).each do |period|
        expect(facility_1_results[period]["monthly_diabetes_registrations"]).to eq 0
        expect(facility_2_results[period]["monthly_diabetes_registrations"]).to eq 0
        expect(region_results[period]["monthly_diabetes_registrations"]).to eq 0
      end

      expect(facility_1_results["Apr 2019".to_period]["monthly_diabetes_registrations"]).to eq 5
      expect(facility_2_results["Apr 2019".to_period]["monthly_diabetes_registrations"]).to eq 6
      expect(region_results["Apr 2019".to_period]["monthly_diabetes_registrations"]).to eq 11

      (("May 2019".to_period)..("Mar 2020".to_period)).each do |period|
        expect(facility_1_results[period]["monthly_diabetes_registrations"]).to eq 0
        expect(facility_2_results[period]["monthly_diabetes_registrations"]).to eq 0
        expect(region_results[period]["monthly_diabetes_registrations"]).to eq 0
      end
    end

    it "returns the number of monthly diabetes follow ups" do
      facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
      create(:blood_pressure, :with_encounter, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:prescription_drug, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
      create(:appointment, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

      facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
      create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
      create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      (("Jan 2020".to_period)..("Feb 2020".to_period)).each do |period|
        expect(facility_1_results[period]["monthly_diabetes_follow_ups"]).to eq 0
        expect(facility_2_results[period]["monthly_diabetes_follow_ups"]).to eq 0
        expect(region_results[period]["monthly_diabetes_follow_ups"]).to eq 0
      end

      expect(facility_1_results["Mar 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 2
      expect(facility_2_results["Mar 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 2
      expect(region_results["Mar 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 4

      expect(facility_1_results["Apr 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 2
      expect(facility_2_results["Apr 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 1
      expect(region_results["Apr 2020".to_period]["monthly_diabetes_follow_ups"]).to eq 3

      (("May 2020".to_period)..("Mar 2021".to_period)).each do |period|
        expect(facility_1_results[period]["monthly_diabetes_follow_ups"]).to eq 0
        expect(facility_2_results[period]["monthly_diabetes_follow_ups"]).to eq 0
        expect(region_results[period]["monthly_diabetes_follow_ups"]).to eq 0
      end
    end
  end

  context "overdue patient" do
    let(:timezone) { Time.find_zone(Period::REPORTING_TIME_ZONE) }
    let(:this_month) { timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0) }
    let(:one_month_ago) { this_month - 1.month }
    let(:two_months_ago) { this_month - 2.month }
    let(:three_months_ago) { this_month - 3.month }
    let(:four_months_ago) { this_month - 4.month }
    let(:five_months_ago) { this_month - 5.month }
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:facility_1) { district_with_facilities[:facility_1] }
    let(:facility_2) { district_with_facilities[:facility_2] }

    xit "return the count of overdue patients" do
      facility_1_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility_1, recorded_at: jan_2019)
      create(:appointment, patient: facility_1_patients.first, scheduled_date: two_months_ago, facility: facility_1, device_created_at: three_months_ago)
      create(:appointment, patient: facility_1_patients.second, scheduled_date: two_months_ago, facility: facility_1, device_created_at: three_months_ago)
      create(:appointment, patient: facility_1_patients.third, scheduled_date: one_month_ago, facility: facility_1, device_created_at: two_months_ago)
      create(:appointment, patient: facility_1_patients.fourth, scheduled_date: one_month_ago, facility: facility_1, device_created_at: three_months_ago)

      facility_2_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: jan_2019)
      create(:appointment, patient: facility_2_patients.first, scheduled_date: two_months_ago, facility: facility_2, device_created_at: three_months_ago)
      create(:appointment, patient: facility_2_patients.second, scheduled_date: two_months_ago, facility: facility_2, device_created_at: three_months_ago)
      create(:appointment, patient: facility_2_patients.third, scheduled_date: one_month_ago, facility: facility_2, device_created_at: two_months_ago)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["overdue_patients"]).to eq 4
      expect(facility_1_results[one_month_ago.to_period]["overdue_patients"]).to eq 2
      expect(facility_2_results[this_month.to_period]["overdue_patients"]).to eq 3
      expect(facility_2_results[one_month_ago.to_period]["overdue_patients"]).to eq 2
      expect(region_results[this_month.to_period]["overdue_patients"]).to eq 7
      expect(region_results[one_month_ago.to_period]["overdue_patients"]).to eq 4

      periods_before_two_months = jan_2019.to_period..two_months_ago.to_period
      periods_before_two_months.each do |period|
        expect(facility_1_results[period]["overdue_patients"]).to eq 0
        expect(facility_2_results[period]["overdue_patients"]).to eq 0
        expect(region_results[period]["overdue_patients"]).to eq 0
      end
    end

    xit "return the count of patients called" do
      create(:user, registration_facility: facility_1)
      create(:user, registration_facility: facility_2)

      facility_1_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_patients.second, device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:call_result, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 4.days)

      facility_2_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, device_created_at: two_months_ago + 2.days)
      create(:call_result, patient: facility_2_patients.fourth, device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_called"]).to eq 3
      expect(facility_1_results[one_month_ago.to_period]["patients_called"]).to eq 1
      expect(facility_1_results[two_months_ago.to_period]["patients_called"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_called"]).to eq 2
      expect(facility_2_results[one_month_ago.to_period]["patients_called"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_called"]).to eq 1
      expect(region_results[this_month.to_period]["patients_called"]).to eq 5
      expect(region_results[one_month_ago.to_period]["patients_called"]).to eq 1
      expect(region_results[two_months_ago.to_period]["patients_called"]).to eq 1

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called"]).to eq 0
        expect(facility_2_results[period]["patients_called"]).to eq 0
        expect(region_results[period]["patients_called"]).to eq 0
      end
    end

    xit "return the count of patients called who agreed to visit" do
      create(:user, registration_facility: facility_1)
      create(:user, registration_facility: facility_2)

      facility_1_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_patients.second, result_type: "agreed_to_visit", device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_patients.third, result_type: "agreed_to_visit", device_created_at: this_month + 27.days)
      create(:call_result, patient: facility_1_patients.fourth, result_type: "remind_to_call_later", device_created_at: one_month_ago + 4.days)

      facility_2_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, result_type: "remind_to_call_later", device_created_at: two_months_ago + 2.days)
      create(:call_result, patient: facility_2_patients.fourth, result_type: "remind_to_call_later", device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 3
      expect(facility_1_results[one_month_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[this_month.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 4
      expect(region_results[one_month_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[two_months_ago.to_period]["patients_called_with_result_agreed_to_visit"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
        expect(region_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      end
    end

    xit "return the count of patients called who needs to be called again later" do
      create(:user, registration_facility: facility_1)
      create(:user, registration_facility: facility_2)

      facility_1_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "remind_to_call_later", device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_patients.second, result_type: "agreed_to_visit", device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_patients.third, result_type: "remind_to_call_later", device_created_at: this_month + 27.days)
      create(:call_result, patient: facility_1_patients.fourth, result_type: "remind_to_call_later", device_created_at: one_month_ago + 4.days)

      facility_2_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, result_type: "remind_to_call_later", device_created_at: two_months_ago + 2.days)
      create(:call_result, patient: facility_2_patients.fourth, result_type: "remind_to_call_later", device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 2
      expect(facility_1_results[one_month_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(facility_1_results[two_months_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(region_results[this_month.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 3
      expect(region_results[one_month_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(region_results[two_months_ago.to_period]["patients_called_with_result_remind_to_call_later"]).to eq 1

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
        expect(region_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
      end
    end

    xit "return the count of patients called and were removed from overdue list" do
      create(:user, registration_facility: facility_1)
      create(:user, registration_facility: facility_2)

      facility_1_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_patients.second, result_type: "agreed_to_visit", device_created_at: this_month + 1.days)
      create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 4.days)

      facility_2_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 12.days)
      create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
      create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.third, device_created_at: two_months_ago + 2.days)
      create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.fourth, device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_called_with_result_removed_from_list"]).to eq 2
      expect(facility_1_results[one_month_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 1
      expect(facility_1_results[two_months_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_called_with_result_removed_from_list"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 1
      expect(region_results[this_month.to_period]["patients_called_with_result_removed_from_list"]).to eq 3
      expect(region_results[one_month_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 1
      expect(region_results[two_months_ago.to_period]["patients_called_with_result_removed_from_list"]).to eq 1

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
        expect(region_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
      end
    end

    xit "return the count of patients returned to care after getting a call" do
      facility_1_patients = create_list(:patient, 4, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
      create(:call_result, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
      create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 28.days)

      facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
      create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_returned_after_call"]).to eq 2
      expect(facility_1_results[one_month_ago.to_period]["patients_returned_after_call"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["patients_returned_after_call"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_returned_after_call"]).to eq 2
      expect(facility_2_results[one_month_ago.to_period]["patients_returned_after_call"]).to eq 1
      expect(facility_2_results[two_months_ago.to_period]["patients_returned_after_call"]).to eq 0
      expect(region_results[this_month.to_period]["patients_returned_after_call"]).to eq 4
      expect(region_results[one_month_ago.to_period]["patients_returned_after_call"]).to eq 1
      expect(region_results[two_months_ago.to_period]["patients_returned_after_call"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_returned_after_call"]).to eq 0
        expect(facility_2_results[period]["patients_returned_after_call"]).to eq 0
        expect(region_results[period]["patients_returned_after_call"]).to eq 0
      end
    end

    xit "return the count of patients returned to care who agreed to visit" do
      facility_1_patients = create_list(:patient, 4, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.third, result_type: "agreed_to_visit", device_created_at: this_month + 12.day)
      create(:call_result, patient: facility_1_patients.fourth, result_type: "remind_to_call_later", device_created_at: one_month_ago + 12.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month)
      create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 28.days)

      facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, result_type: "remind_to_call_later", device_created_at: one_month_ago.end_of_month.beginning_of_day)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
      create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 3
      expect(facility_1_results[one_month_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[this_month.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 4
      expect(region_results[one_month_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[two_months_ago.to_period]["patients_returned_with_result_agreed_to_visit"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
        expect(facility_2_results[period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
        expect(region_results[period]["patients_returned_with_result_agreed_to_visit"]).to eq 0
      end
    end

    xit "return the count of patients returned to care who needs to be called again later" do
      facility_1_patients = create_list(:patient, 4, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "remind_to_call_later", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, result_type: "remind_to_call_later", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.third, result_type: "remind_to_call_later", device_created_at: this_month + 12.day)
      create(:call_result, patient: facility_1_patients.fourth, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: one_month_ago + 12.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month)
      create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 28.days)

      facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "remind_to_call_later", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: one_month_ago.end_of_month.beginning_of_day)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
      create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 3
      expect(facility_1_results[one_month_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      expect(region_results[this_month.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 4
      expect(region_results[one_month_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      expect(region_results[two_months_ago.to_period]["patients_returned_with_result_remind_to_call_later"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
        expect(facility_2_results[period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
        expect(region_results[period]["patients_returned_with_result_remind_to_call_later"]).to eq 0
      end
    end

    xit "return the count of patients returned to care who were removed from overdue list" do
      facility_1_patients = create_list(:patient, 4, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "removed_from_overdue_list", remove_reason: "invalid_phone_number", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, result_type: "removed_from_overdue_list", remove_reason: "invalid_phone_number", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.third, result_type: "removed_from_overdue_list", remove_reason: "invalid_phone_number", device_created_at: this_month + 12.day)
      create(:call_result, patient: facility_1_patients.fourth, result_type: "agreed_to_visit", device_created_at: one_month_ago + 12.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month)
      create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 28.days)

      facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "removed_from_overdue_list", remove_reason: "invalid_phone_number", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "agreed_to_visit", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_patients.third, result_type: "agreed_to_visit", device_created_at: one_month_ago.end_of_month.beginning_of_day)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
      create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["patients_returned_with_result_removed_from_list"]).to eq 3
      expect(facility_1_results[one_month_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0
      expect(facility_2_results[this_month.to_period]["patients_returned_with_result_removed_from_list"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0
      expect(facility_2_results[two_months_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0
      expect(region_results[this_month.to_period]["patients_returned_with_result_removed_from_list"]).to eq 4
      expect(region_results[one_month_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0
      expect(region_results[two_months_ago.to_period]["patients_returned_with_result_removed_from_list"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_returned_with_result_removed_from_list"]).to eq 0
        expect(facility_2_results[period]["patients_returned_with_result_removed_from_list"]).to eq 0
        expect(region_results[period]["patients_returned_with_result_removed_from_list"]).to eq 0
      end
    end

    it "return the count of contactable patients called" do
      facility_1_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :hypertension, :removed_from_overdue_list, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_contactable_patients.first, device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_contactable_patients.second, device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_contactable_patients.third, device_created_at: two_months_ago + 1.days)
      create(:call_result, patient: facility_1_patient_with_out_phone, device_created_at: this_month + 27.days)
      create(:call_result, patient: facility_1_patient_removed_from_list, device_created_at: this_month + 4.days)

      facility_2_contactable_patients = create_list(:patient, 2, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_contactable_patients.first, device_created_at: this_month)
      create(:call_result, patient: facility_2_contactable_patients.second, device_created_at: one_month_ago + 3.days)
      create(:call_result, patient: facility_2_patient_with_out_phone, device_created_at: this_month + 2.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_called"]).to eq 2
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_called"]).to eq 1 # Call made to facility_1_patient_removed_from_list with result type 'removed from list' before 'this_month'
      expect(facility_1_results[two_months_ago.to_period]["contactable_patients_called"]).to eq 1
      expect(facility_2_results[this_month.to_period]["contactable_patients_called"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_called"]).to eq 1
      expect(facility_2_results[two_months_ago.to_period]["contactable_patients_called"]).to eq 0
      expect(region_results[this_month.to_period]["contactable_patients_called"]).to eq 3
      expect(region_results[one_month_ago.to_period]["contactable_patients_called"]).to eq 2
      expect(region_results[two_months_ago.to_period]["contactable_patients_called"]).to eq 1

      periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["contactable_patients_called"]).to eq 0
        expect(facility_2_results[period]["contactable_patients_called"]).to eq 0
        expect(region_results[period]["contactable_patients_called"]).to eq 0
      end
    end

    it "return the count of contactable patients called who agreed to visit" do
      facility_1_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :hypertension, :removed_from_overdue_list, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_1_patient_with_out_phone, result_type: "agreed_to_visit", device_created_at: one_month_ago + 27.days)
      create(:call_result, patient: facility_1_patient_removed_from_list, result_type: "agreed_to_visit", device_created_at: this_month + 4.days)

      facility_2_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_2_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_2_patient_with_out_phone, result_type: "agreed_to_visit", device_created_at: one_month_ago + 2.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 1
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[this_month.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[this_month.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 2
      expect(region_results[one_month_ago.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[two_months_ago.to_period]["contactable_patients_called_with_result_agreed_to_visit"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..two_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
        expect(region_results[period]["patients_called_with_result_agreed_to_visit"]).to eq 0
      end
    end

    it "return the count of contactable patients called who needs to be called again later" do
      facility_1_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :hypertension, :removed_from_overdue_list, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_1_patient_with_out_phone, result_type: "remind_to_call_later", device_created_at: one_month_ago + 27.days)
      create(:call_result, patient: facility_1_patient_removed_from_list, result_type: "remind_to_call_later", device_created_at: this_month + 4.days)

      facility_2_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_2_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_2_patient_with_out_phone, result_type: "remind_to_call_later", device_created_at: one_month_ago + 2.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(facility_1_results[two_months_ago.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(facility_2_results[this_month.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(region_results[this_month.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 2
      expect(region_results[one_month_ago.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 0
      expect(region_results[two_months_ago.to_period]["contactable_patients_called_with_result_remind_to_call_later"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..two_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
        expect(region_results[period]["patients_called_with_result_remind_to_call_later"]).to eq 0
      end
    end

    it "return the count of contactable patients called and were removed from overdue list" do
      facility_1_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :hypertension, :removed_from_overdue_list, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 15.days)
      create(:call_result, patient: facility_1_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 1.days)
      create(:call_result, patient: facility_1_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_1_patient_with_out_phone, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: one_month_ago + 27.days)
      create(:call_result, patient: facility_1_patient_removed_from_list, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month + 4.days)

      facility_2_contactable_patients = create_list(:patient, 3, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_with_out_phone = create(:patient, :hypertension, :without_phone_number, assigned_facility: facility_2, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_contactable_patients.first, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_2_contactable_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 3.days)
      create(:call_result, patient: facility_2_contactable_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_2_patient_with_out_phone, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: one_month_ago + 2.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 1
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 1 # Call made to facility_1_patient_removed_from_list with result type 'removed from list' before 'this_month'
      expect(facility_1_results[two_months_ago.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 0
      expect(facility_2_results[this_month.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 0
      expect(region_results[this_month.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 2
      expect(region_results[one_month_ago.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 1
      expect(region_results[two_months_ago.to_period]["contactable_patients_called_with_result_removed_from_list"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..two_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
        expect(facility_2_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
        expect(region_results[period]["patients_called_with_result_removed_from_list"]).to eq 0
      end
    end

    it "return the count of contactable patients returned to care after getting a call" do
      facility_1_patients = create_list(:patient, 2, :contactable_overdue, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_without_phone = create(:patient, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :removed_from_overdue_list, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, device_created_at: this_month + 15.day)
      create(:call_result, patient: facility_1_patient_without_phone, device_created_at: one_month_ago + 12.day)
      create(:call_result, patient: facility_1_patient_removed_from_list, device_created_at: this_month + 3.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 30.days)
      create(:blood_pressure, patient: facility_1_patient_without_phone, device_created_at: one_month_ago + 27.days)
      create(:blood_pressure, patient: facility_1_patient_removed_from_list, device_created_at: this_month + 18.days)

      facility_2_patients = create_list(:patient, 2, :contactable_overdue, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_without_phone = create(:patient, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, device_created_at: one_month_ago.end_of_month.beginning_of_day)
      create(:call_result, patient: facility_2_patient_without_phone, device_created_at: one_month_ago + 3.days)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: one_month_ago.end_of_month.beginning_of_day + 14.days)
      create(:blood_pressure, patient: facility_2_patient_without_phone, device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_returned_after_call"]).to eq 2
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_returned_after_call"]).to eq 0
      expect(facility_2_results[this_month.to_period]["contactable_patients_returned_after_call"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_returned_after_call"]).to eq 1
      expect(region_results[this_month.to_period]["contactable_patients_returned_after_call"]).to eq 3
      expect(region_results[one_month_ago.to_period]["contactable_patients_returned_after_call"]).to eq 1

      periods_before_three_months = five_months_ago.to_period..two_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["contactable_patients_returned_after_call"]).to eq 0
        expect(facility_2_results[period]["contactable_patients_returned_after_call"]).to eq 0
        expect(region_results[period]["contactable_patients_returned_after_call"]).to eq 0
      end
    end

    it "return the count of contactable patients returned to care who agreed to visit" do
      facility_1_patients = create_list(:patient, 3, :contactable_overdue, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_without_phone = create(:patient, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      facility_1_patient_removed_from_list = create(:patient, :removed_from_overdue_list, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_1_patients.first, result_type: "agreed_to_visit", device_created_at: this_month)
      create(:call_result, patient: facility_1_patients.second, result_type: "remind_to_call_later", device_created_at: this_month + 15.day)
      create(:call_result, patient: facility_1_patients.third, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_1_patient_without_phone, result_type: "agreed_to_visit", device_created_at: one_month_ago + 12.day)
      create(:call_result, patient: facility_1_patient_removed_from_list, result_type: "agreed_to_visit", device_created_at: this_month + 3.day)

      create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
      create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 30.days)
      create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 12.days)
      create(:blood_pressure, patient: facility_1_patient_without_phone, device_created_at: one_month_ago + 27.days)
      create(:blood_pressure, patient: facility_1_patient_removed_from_list, device_created_at: this_month + 18.days)

      facility_2_patients = create_list(:patient, 3, :contactable_overdue, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
      facility_2_patient_without_phone = create(:patient, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
      create(:call_result, patient: facility_2_patients.first, result_type: "agreed_to_visit", device_created_at: this_month + 12.days)
      create(:call_result, patient: facility_2_patients.second, result_type: "remind_to_call_later", device_created_at: this_month)
      create(:call_result, patient: facility_2_patients.second, result_type: "removed_from_overdue_list", remove_reason: "other", device_created_at: this_month)
      create(:call_result, patient: facility_2_patient_without_phone, result_type: "agreed_to_visit", device_created_at: one_month_ago + 3.days)

      create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 14.days)
      create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 7.days)
      create(:blood_pressure, patient: facility_2_patient_without_phone, device_created_at: one_month_ago + 15.days)

      refresh_views
      facility_1_results = described_class.call(facility_1)[facility_1.region.slug]
      facility_2_results = described_class.call(facility_2)[facility_2.region.slug]
      region_results = described_class.call(region)[region.slug]

      expect(facility_1_results[this_month.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 1
      expect(facility_1_results[one_month_ago.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(facility_2_results[this_month.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 1
      expect(facility_2_results[one_month_ago.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0
      expect(region_results[this_month.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 2
      expect(region_results[one_month_ago.to_period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0

      periods_before_three_months = five_months_ago.to_period..two_months_ago.to_period
      periods_before_three_months.each do |period|
        expect(facility_1_results[period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0
        expect(facility_2_results[period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0
        expect(region_results[period]["contactable_patients_returned_with_result_agreed_to_visit"]).to eq 0
      end
    end

    xit "return the count of contactable patients returned to care who needs to be called again later" do
    end

    xit "return the count of contactable patients returned to care who were removed from overdue list" do
    end
  end

  describe "#for_regions" do
    it "excludes facilities where registrations, assigned patients and follow ups are all zero" do
      facility = create(:facility, created_at: 1.year.ago)
      range = Period.month(2.years.ago)..Period.current
      create(:patient, assigned_facility: facility, recorded_at: Date.today)

      RefreshReportingViews.refresh_v2

      expect(described_class.new(facility, range: range).for_regions.where("month_date < ?", Period.current.to_date)).to be_empty
      expect(described_class.new(facility, range: range).for_regions.where("month_date = ?", Period.current.to_date)).not_to be_empty
    end
  end
end
