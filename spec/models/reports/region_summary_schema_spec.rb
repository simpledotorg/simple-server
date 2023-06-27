require "rails_helper"

describe Reports::RegionSummarySchema, type: :model do
  using StringToPeriod

  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  let(:range) { (july_2018..june_2020) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility) { create(:facility, name: "facility-1", facility_group: facility_group_1) }

  let(:jan_2019) { Time.zone.parse("January 1st, 2019 00:00:00+00:00") }
  let(:feb_2019) { Time.zone.parse("February 1st, 2019 00:00:00+00:00") }
  let(:mar_2019) { Time.zone.parse("March 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.zone.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Period.month("July 1 2018") }
  let(:june_2020) { Period.month("June 1 2020") }

  def refresh_views
    RefreshReportingViews.refresh_v2
  end

  it "returns data correctly grouped when passed mixed region types" do
    facility_1, facility_2 = *FactoryBot.create_list(:facility, 2, block: "block-1", facility_group: facility_group_1).sort_by(&:slug)
    facility_3 = FactoryBot.create(:facility, block: "block-2", facility_group: facility_group_1)
    facilities = [facility_1, facility_2, facility_3]

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
    end

    refresh_views

    regions = [facility_group_1.region].concat(facilities.map(&:region))
    july_2021 = Period.month("July 1st 2021")
    range = (july_2021.advance(months: -24)..july_2021)
    result = described_class.new(regions, periods: range).send(:region_summaries)

    expect(result[facility_group_1.slug][jan_2020.to_period]).to include("cumulative_assigned_patients" => 5)
    expect(result[facility_group_1.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 3)
    expect(result[facility_1.region.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 2)
    expect(result[facility_2.region.slug][jan_2020.to_period]).to include("adjusted_controlled_under_care" => 1)
  end

  it "can return earliest patient recorded at" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility, registration_user: user) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    expect(schema.earliest_patient_recorded_at[facility.region.slug]).to eq(jan_2020)
  end

  it "has cache key" do
    Timecop.freeze(jan_2020) { create(:patient, assigned_facility: facility, registration_user: user) }

    refresh_views

    schema = described_class.new([facility.region], periods: range)
    entries = schema.cache_entries(:earliest_patient_recorded_at)
    entries.each do |entry|
      expect(entry.to_s).to include("region_summary_schema")
      expect(entry.to_s).to include(facility.region.id)
      expect(entry.to_s).to include(schema.cache_version)
    end
  end

  describe "appointment scheduled days percentages" do
    it "returns percentages of appointments scheduled across months in a given range" do
      facility = create(:facility, enable_diabetes_management: true)
      htn_patient = create(:patient, :hypertension, assigned_facility: facility, recorded_at: 1.month.ago)
      diabetes_patient = create(:patient, :diabetes, assigned_facility: facility, recorded_at: 1.month.ago)
      range = Period.month(2.month.ago)..Period.current
      _htn_appointment_scheduled_0_to_14_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)
      _diabetes_appointment_scheduled_0_to_14_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: 10.days.from_now, device_created_at: Date.today)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.first]).to eq(0)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.to_a.second]).to eq(0)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(100)

      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][range.first]).to eq(0)
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][range.to_a.second]).to eq(0)
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(100)
    end

    it "returns percentages of appointments scheduled in a month in the given range" do
      facility = create(:facility, enable_diabetes_management: true)
      htn_patient = create(:patient, :hypertension, assigned_facility: facility, recorded_at: 4.month.ago)
      diabetes_patient = create(:patient, :diabetes, assigned_facility: facility, recorded_at: 4.month.ago)
      range = Period.month(2.month.ago)..Period.current
      _appointment_scheduled_0_to_14_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: 14.days.from_now, device_created_at: Date.today)
      _appointment_scheduled_15_to_30_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: 1.month.ago + 15.days, device_created_at: 1.month.ago)
      _appointment_scheduled_more_than_62_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: 2.month.ago + 63.days, device_created_at: 2.month.ago)
      _diabetes_appointment_scheduled_0_to_14_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: 14.days.from_now, device_created_at: Date.today)
      _diabetes_appointment_scheduled_15_to_30_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: 1.month.ago + 16.days, device_created_at: 1.month.ago)
      _diabetes_appointment_scheduled_more_than_62_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: 2.month.ago + 63.days, device_created_at: 2.month.ago)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.region.slug][range.last]).to eq(100)
      expect(schema.appts_scheduled_15_to_31_days_rates[facility.region.slug][range.to_a.second]).to eq(100)
      expect(schema.appts_scheduled_more_than_62_days_rates[facility.region.slug][range.first]).to eq(100)
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.region.slug][range.last]).to eq(100)
      expect(schema.diabetes_appts_scheduled_15_to_31_days_rates[facility.region.slug][range.to_a.second]).to eq(100)
      expect(schema.diabetes_appts_scheduled_more_than_62_days_rates[facility.region.slug][range.first]).to eq(100)
    end

    it "returns percentages of appointments scheduled in a month in the given range for appointments created in a given month" do
      facility = create(:facility, enable_diabetes_management: true)
      htn_patients = create_list(:patient, 4, :hypertension, assigned_facility: facility, recorded_at: 4.month.ago)
      diabetes_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility, recorded_at: 4.month.ago)
      range = Period.current..Period.month(2.months.from_now)
      _appointment_scheduled_0_to_14_days = create(:appointment, patient: htn_patients.first, facility: facility, scheduled_date: 14.days.from_now)
      _appointment_scheduled_15_to_31_days = create(:appointment, patient: htn_patients.second, facility: facility, scheduled_date: 15.days.from_now)
      _appointment_scheduled_32_to_62_days = create(:appointment, patient: htn_patients.third, facility: facility, scheduled_date: 32.days.from_now)
      _appointment_scheduled_more_than_62_days = create(:appointment, patient: htn_patients.fourth, facility: facility, scheduled_date: 63.days.from_now)
      _diabetes_appointment_scheduled_0_to_14_days = create(:appointment, patient: diabetes_patients.first, facility: facility, scheduled_date: 14.days.from_now)
      _diabetes_appointment_scheduled_15_to_31_days = create(:appointment, patient: diabetes_patients.second, facility: facility, scheduled_date: 15.days.from_now)
      _diabetes_appointment_scheduled_32_to_62_days = create(:appointment, patient: diabetes_patients.third, facility: facility, scheduled_date: 32.days.from_now)
      _diabetes_appointment_scheduled_more_than_62_days = create(:appointment, patient: diabetes_patients.fourth, facility: facility, scheduled_date: 63.days.from_now)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.appts_scheduled_15_to_31_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.appts_scheduled_32_to_62_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.appts_scheduled_more_than_62_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.diabetes_appts_scheduled_15_to_31_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.diabetes_appts_scheduled_32_to_62_days_rates[facility.slug][Period.current]).to eq(25)
      expect(schema.diabetes_appts_scheduled_more_than_62_days_rates[facility.slug][Period.current]).to eq(25)
    end

    it "considers the latest appointment scheduled in case of multiple appointments in the same month " do
      facility = create(:facility, enable_diabetes_management: true)
      htn_patient = create(:patient, :hypertension, assigned_facility: facility, recorded_at: 4.month.ago)
      diabetes_patient = create(:patient, :diabetes, assigned_facility: facility, recorded_at: 4.month.ago)
      range = Period.month(2.month.ago)..Period.current
      today = Time.current.beginning_of_month

      _appointment_scheduled_0_to_14_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: today + 10.day, device_created_at: today + 3.day)
      _appointment_scheduled_15_to_30_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: today + 20.day, device_created_at: today + 4.day)
      _appointment_scheduled_31_to_62_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: today + 32.day, device_created_at: today + 1.day)
      _appointment_scheduled_more_than_62_days = create(:appointment, patient: htn_patient, facility: facility, scheduled_date: today + 64.day, device_created_at: today + 2.day)

      _diabetes_appointment_scheduled_0_to_14_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: today + 10.day, device_created_at: today + 2.day)
      _diabetes_appointment_scheduled_15_to_30_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: today + 19.day, device_created_at: today + 3.day)
      _diabetes_appointment_scheduled_31_to_62_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: today + 36.day, device_created_at: today + 4.day)
      _diabetes_appointment_scheduled_more_than_62_days = create(:appointment, patient: diabetes_patient, facility: facility, scheduled_date: today + 62.day, device_created_at: today + 1.day)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)
      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(0)
      expect(schema.appts_scheduled_15_to_31_days_rates[facility.slug][range.last]).to eq(100)
      expect(schema.appts_scheduled_32_to_62_days_rates[facility.slug][range.last]).to eq(0)
      expect(schema.appts_scheduled_more_than_62_days_rates[facility.slug][range.last]).to eq(0)

      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][range.last]).to eq(0)
      expect(schema.diabetes_appts_scheduled_15_to_31_days_rates[facility.slug][range.last]).to eq(0)
      expect(schema.diabetes_appts_scheduled_32_to_62_days_rates[facility.slug][range.last]).to eq(100)
      expect(schema.diabetes_appts_scheduled_more_than_62_days_rates[facility.slug][range.last]).to eq(0)
    end

    it "returns zeros when there is no appointment data in the month" do
      facility = create(:facility, enable_diabetes_management: true)
      create(:patient, :hypertension, assigned_facility: facility)
      create(:patient, :diabetes, assigned_facility: facility)
      period = Period.current

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)

      expect(schema.appts_scheduled_0_to_14_days[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_15_to_31_days[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_32_to_62_days[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_more_than_62_days[facility.slug][period]).to eq(0)
      expect(schema.total_appts_scheduled[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_0_to_14_days[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_15_to_31_days[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_32_to_62_days[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_more_than_62_days[facility.slug][period]).to eq(0)
      expect(schema.diabetes_total_appts_scheduled[facility.slug][period]).to eq(0)

      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_15_to_31_days_rates[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_32_to_62_days_rates[facility.slug][period]).to eq(0)
      expect(schema.appts_scheduled_more_than_62_days_rates[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_15_to_31_days_rates[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_32_to_62_days_rates[facility.slug][period]).to eq(0)
      expect(schema.diabetes_appts_scheduled_more_than_62_days_rates[facility.slug][period]).to eq(0)
    end

    it "returns empty hashes when there is no registered patients, assigned patients or follow ups" do
      facility = create(:facility, enable_diabetes_management: true)

      refresh_views

      schema = described_class.new(Region.where(id: facility.region), periods: range)

      expect(schema.appts_scheduled_0_to_14_days[facility.slug]).to eq({})
      expect(schema.appts_scheduled_15_to_31_days[facility.slug]).to eq({})
      expect(schema.appts_scheduled_32_to_62_days[facility.slug]).to eq({})
      expect(schema.appts_scheduled_more_than_62_days[facility.slug]).to eq({})
      expect(schema.total_appts_scheduled[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_0_to_14_days[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_15_to_31_days[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_32_to_62_days[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_more_than_62_days[facility.slug]).to eq({})
      expect(schema.diabetes_total_appts_scheduled[facility.slug]).to eq({})

      expect(schema.appts_scheduled_0_to_14_days_rates[facility.slug]).to eq({})
      expect(schema.appts_scheduled_15_to_31_days_rates[facility.slug]).to eq({})
      expect(schema.appts_scheduled_32_to_62_days_rates[facility.slug]).to eq({})
      expect(schema.appts_scheduled_more_than_62_days_rates[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_0_to_14_days_rates[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_15_to_31_days_rates[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_32_to_62_days_rates[facility.slug]).to eq({})
      expect(schema.diabetes_appts_scheduled_more_than_62_days_rates[facility.slug]).to eq({})
    end
  end

  describe "diabetes" do
    let(:distict_with_facilities) { setup_district_with_facilities }
    let(:region) { distict_with_facilities[:region] }
    let(:facility_1) { distict_with_facilities[:facility_1] }
    let(:facility_2) { distict_with_facilities[:facility_2] }
    let(:period) { jan_2020..mar_2020 }

    before :each do
      facility_1.update(enable_diabetes_management: true)
      facility_2.update(enable_diabetes_management: true)
    end

    describe "#bs_below_200_rates" do
      it "returns the bs_below_200 rates over time for a region" do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
          [facility_1.region, facility_2.region, region].each do |r|
            expect(schema.bs_below_200_rates[r.slug][period]).to eq(0)
            expect(schema.bs_below_200_rates(with_ltfu: true)[r.slug][period]).to eq(0)
          end
        end

        expect(schema.bs_below_200_rates[facility_1.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_below_200_rates(with_ltfu: true)[facility_1.region.slug]["Mar 2020".to_period]).to eq(50)

        expect(schema.bs_below_200_rates[facility_2.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_below_200_rates(with_ltfu: true)[facility_2.region.slug]["Mar 2020".to_period]).to eq(67)

        expect(schema.bs_below_200_rates[region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_below_200_rates(with_ltfu: true)[region.slug]["Mar 2020".to_period]).to eq(57)
      end
    end

    describe "#bs_200_to_300_rates" do
      it "returns the bs_200_to_300 rates over time for a region" do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_200_to_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_200_to_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
          [facility_1.region, facility_2.region, region].each do |r|
            expect(schema.bs_200_to_300_rates[r.slug][period]).to eq(0)
            expect(schema.bs_200_to_300_rates(with_ltfu: true)[r.slug][period]).to eq(0)
          end
        end

        expect(schema.bs_200_to_300_rates[facility_1.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_200_to_300_rates(with_ltfu: true)[facility_1.region.slug]["Mar 2020".to_period]).to eq(50)

        expect(schema.bs_200_to_300_rates[facility_2.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_200_to_300_rates(with_ltfu: true)[facility_2.region.slug]["Mar 2020".to_period]).to eq(67)

        expect(schema.bs_200_to_300_rates[region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_200_to_300_rates(with_ltfu: true)[region.slug]["Mar 2020".to_period]).to eq(57)
      end
    end

    describe "#bs_over_300_rates" do
      it "returns the bs_over_300 rates over time for a region" do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_over_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        (("Jan 2019".to_period)..("Feb 2020".to_period)).each do |period|
          [facility_1.region, facility_2.region, region].each do |r|
            expect(schema.bs_over_300_rates[r.slug][period]).to eq(0)
            expect(schema.bs_over_300_rates(with_ltfu: true)[r.slug][period]).to eq(0)
          end
        end

        expect(schema.bs_over_300_rates[facility_1.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_over_300_rates(with_ltfu: true)[facility_1.region.slug]["Mar 2020".to_period]).to eq(50)

        expect(schema.bs_over_300_rates[facility_2.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_over_300_rates(with_ltfu: true)[facility_2.region.slug]["Mar 2020".to_period]).to eq(67)

        expect(schema.bs_over_300_rates[region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.bs_over_300_rates(with_ltfu: true)[region.slug]["Mar 2020".to_period]).to eq(57)
      end
    end

    describe "#diabetes_missed_visits_rates" do
      it "returns the percentage of patients with missed visits in a region" do
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
        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        (("Jan 2019".to_period)..("Mar 2019".to_period)).each do |period|
          [facility_1.region, facility_2.region, region].each do |r|
            expect(schema.diabetes_missed_visits_rates[r.slug][period]).to eq 0
            expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[r.slug][period]).to eq(0)
          end
        end

        (("Apr 2019".to_period)..("Dec 2019".to_period)).each do |period|
          expect(schema.diabetes_missed_visits_rates[facility_1.region.slug][period]).to eq(100)
          expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug][period]).to eq(100)

          expect(schema.diabetes_missed_visits_rates[facility_2.region.slug][period]).to eq(100)
          expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug][period]).to eq(100)
        end

        (("Jan 2020".to_period)..("Feb 2020".to_period)).each do |period|
          expect(schema.diabetes_missed_visits_rates[facility_1.region.slug][period]).to eq 0
          expect(schema.diabetes_missed_visits_rates[facility_2.region.slug][period]).to eq 0
        end

        (("Jan 2020".to_period)..("Feb 2020".to_period)).each do |period|
          expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug][period]).to eq 100
          expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug][period]).to eq 100
        end

        expect(schema.diabetes_missed_visits_rates[facility_1.region.slug]["Apr 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug]["Apr 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates[facility_2.region.slug]["Apr 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug]["Apr 2020".to_period]).to eq(0)

        expect(schema.diabetes_missed_visits_rates[facility_1.region.slug]["Mar 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug]["Mar 2020".to_period]).to eq(50)
        expect(schema.diabetes_missed_visits_rates[facility_2.region.slug]["Mar 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug]["Mar 2020".to_period]).to eq(33)

        expect(schema.diabetes_missed_visits_rates[facility_1.region.slug]["May 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug]["May 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates[facility_2.region.slug]["May 2020".to_period]).to eq(0)
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug]["May 2020".to_period]).to eq(0)

        expect(schema.diabetes_missed_visits_rates[facility_1.region.slug]["Jun 2020".to_period]).to eq 50
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_1.region.slug]["Jun 2020".to_period]).to eq 50
        expect(schema.diabetes_missed_visits_rates[facility_2.region.slug]["Jun 2020".to_period]).to eq 67
        expect(schema.diabetes_missed_visits_rates(with_ltfu: true)[facility_2.region.slug]["Jun 2020".to_period]).to eq 67
      end
    end

    describe "#visited_without_bs_taken_rates" do
      it "returns the percentage of patients who visited without bs taken in a region" do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:prescription_drug, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:appointment, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_pressure, :with_encounter, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:prescription_drug, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:appointment, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views
        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        expect(schema.visited_without_bs_taken_rates[facility_1.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_1.region.slug]["Mar 2020".to_period]).to eq(50)
        expect(schema.visited_without_bs_taken_rates[facility_2.region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_2.region.slug]["Mar 2020".to_period]).to eq(67)
        expect(schema.visited_without_bs_taken_rates[region.slug]["Mar 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[region.slug]["Mar 2020".to_period]).to eq(57)

        expect(schema.visited_without_bs_taken_rates[facility_1.region.slug]["Apr 2020".to_period]).to eq(75)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_1.region.slug]["Apr 2020".to_period]).to eq(75)
        expect(schema.visited_without_bs_taken_rates[facility_2.region.slug]["Apr 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_2.region.slug]["Apr 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates[region.slug]["Apr 2020".to_period]).to eq(86)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[region.slug]["Apr 2020".to_period]).to eq(86)

        expect(schema.visited_without_bs_taken_rates[facility_1.region.slug]["May 2020".to_period]).to eq(75)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_1.region.slug]["May 2020".to_period]).to eq(75)
        expect(schema.visited_without_bs_taken_rates[facility_2.region.slug]["May 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[facility_2.region.slug]["May 2020".to_period]).to eq(100)
        expect(schema.visited_without_bs_taken_rates[region.slug]["May 2020".to_period]).to eq(86)
        expect(schema.visited_without_bs_taken_rates(with_ltfu: true)[region.slug]["May 2020".to_period]).to eq(86)
      end
    end

    describe "diabetes_treatment_outcome_breakdown_rates" do
      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs <200 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 33, post_prandial: 33, fasting: 34, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 33, fasting: 33, hba1c: 34})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[region.slug]["Apr 2020".to_period])
          .to eq({random: 17, post_prandial: 33, fasting: 33, hba1c: 17})
      end

      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs 200-299 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_200_to_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_200_to_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 33, post_prandial: 33, fasting: 34, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 33, fasting: 33, hba1c: 34})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[region.slug]["Apr 2020".to_period])
          .to eq({random: 17, post_prandial: 33, fasting: 33, hba1c: 17})
      end

      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs >=300 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_over_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 50, fasting: 50, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 33, post_prandial: 33, fasting: 34, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 33, fasting: 33, hba1c: 34})
        expect(schema.diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[region.slug]["Apr 2020".to_period])
          .to eq({random: 17, post_prandial: 33, fasting: 33, hba1c: 17})
      end
    end

    describe "diabetes_treatment_outcome_breakdown_counts" do
      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs <200 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_below_200, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 2, fasting: 2, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 1})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 2, fasting: 2, hba1c: 1})
      end

      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs 200-299 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_200_to_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_200_to_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 2, fasting: 2, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 1})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 2, fasting: 2, hba1c: 1})
      end

      it "returns the breakdown of different blood sugar types of the diabetes outcome - bs >=300 " do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_over_300, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_over_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[facility_1.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[facility_2.region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[region.slug]["Mar 2020".to_period])
          .to eq({random: 0, post_prandial: 2, fasting: 2, hba1c: 0})

        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[facility_1.region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 1, fasting: 1, hba1c: 0})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[facility_2.region.slug]["Apr 2020".to_period])
          .to eq({random: 0, post_prandial: 1, fasting: 1, hba1c: 1})
        expect(schema.diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[region.slug]["Apr 2020".to_period])
          .to eq({random: 1, post_prandial: 2, fasting: 2, hba1c: 1})
      end
    end

    describe "#diabetes_patients_with_bs_taken" do
      it "returns the total number of patients with a blood sugar measured in the last 3 months" do
        facility_1_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 3, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_below_200, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_200_to_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        expect(schema.diabetes_patients_with_bs_taken[facility_1.region.slug]["Mar 2020".to_period]).to eq(2)
        expect(schema.diabetes_patients_with_bs_taken[facility_2.region.slug]["Mar 2020".to_period]).to eq(2)
        expect(schema.diabetes_patients_with_bs_taken[region.slug]["Mar 2020".to_period]).to eq(4)

        expect(schema.diabetes_patients_with_bs_taken[facility_1.region.slug]["Apr 2020".to_period]).to eq(3)
        expect(schema.diabetes_patients_with_bs_taken[facility_2.region.slug]["Apr 2020".to_period]).to eq(3)
        expect(schema.diabetes_patients_with_bs_taken[region.slug]["Apr 2020".to_period]).to eq(6)

        expect(schema.diabetes_patients_with_bs_taken[facility_1.region.slug]["July 2020".to_period]).to eq(0)
        expect(schema.diabetes_patients_with_bs_taken[facility_2.region.slug]["July 2020".to_period]).to eq(0)
        expect(schema.diabetes_patients_with_bs_taken[region.slug]["July 2020".to_period]).to eq(0)
      end
    end

    describe "#diabetes_patients_with_bs_taken_breakdown_rates" do
      it "returns the breakdown of different blood sugar measurement type" do
        facility_1_patients = create_list(:patient, 5, :diabetes, assigned_facility: facility_1, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_1_patients.first, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_1_patients.second, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_1_patients.third, facility: facility_1, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_1_patients.fourth, facility: facility_1, recorded_at: jan_2020 + 3.months)
        create(:blood_pressure, :with_encounter, patient: facility_1_patients.fifth, facility: facility_1, recorded_at: jan_2020 + 3.months)

        facility_2_patients = create_list(:patient, 4, :diabetes, assigned_facility: facility_2, recorded_at: jan_2019)
        create(:blood_sugar, :with_encounter, :random, :bs_below_200, patient: facility_2_patients.first, facility: facility_2, recorded_at: jan_2020 + 3.months)
        create(:blood_sugar, :with_encounter, :post_prandial, :bs_200_to_300, patient: facility_2_patients.second, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :fasting, :bs_over_300, patient: facility_2_patients.third, facility: facility_2, recorded_at: jan_2020 + 2.months)
        create(:blood_sugar, :with_encounter, :hba1c, :bs_over_300, patient: facility_2_patients.fourth, facility: facility_2, recorded_at: jan_2020 + 3.months)

        refresh_views

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        [facility_1.region, facility_2.region, region].each do |r|
          expect(schema.diabetes_patients_with_bs_taken_breakdown_rates[r.slug]["Apr 2020".to_period])
            .to eq(
              [:bs_below_200, :random] => 25,
              [:bs_below_200, :post_prandial] => 0,
              [:bs_below_200, :fasting] => 0,
              [:bs_below_200, :hba1c] => 0,
              [:bs_200_to_300, :random] => 0,
              [:bs_200_to_300, :post_prandial] => 25,
              [:bs_200_to_300, :fasting] => 0,
              [:bs_200_to_300, :hba1c] => 0,
              [:bs_over_300, :random] => 0,
              [:bs_over_300, :post_prandial] => 0,
              [:bs_over_300, :fasting] => 25,
              [:bs_over_300, :hba1c] => 25
            )
        end

        [facility_1.region, facility_2.region, region].each do |r|
          expect(schema.diabetes_patients_with_bs_taken_breakdown_rates[r.slug]["Jun 2020".to_period])
            .to include(
              [:bs_below_200, :random] => 50,
              [:bs_below_200, :post_prandial] => 0,
              [:bs_below_200, :fasting] => 0,
              [:bs_below_200, :hba1c] => 0,
              [:bs_200_to_300, :random] => 0,
              [:bs_200_to_300, :post_prandial] => 0,
              [:bs_200_to_300, :fasting] => 0,
              [:bs_200_to_300, :hba1c] => 0,
              [:bs_over_300, :random] => 0,
              [:bs_over_300, :post_prandial] => 0,
              [:bs_over_300, :fasting] => 0,
              [:bs_over_300, :hba1c] => 50
            )
        end

        [facility_1.region, facility_2.region, region].each do |r|
          expect(schema.diabetes_patients_with_bs_taken_breakdown_rates[r.slug]["Jul 2020".to_period])
            .to eq(0)
        end
      end
    end
  end

  describe "hypertension and diabetes" do
    let(:distict_with_facilities) { setup_district_with_facilities }
    let(:region) { distict_with_facilities[:region] }
    let(:facility_1) { distict_with_facilities[:facility_1] }
    let(:facility_2) { distict_with_facilities[:facility_2] }

    it "returns the number of patients registered who have both hypertension and diabetes" do
      create(:patient, :diabetes, registration_facility: facility_1, recorded_at: jan_2019)
      create(:patient, :hypertension, registration_facility: facility_1, recorded_at: jan_2019)
      create(:patient, :hypertension_and_diabetes, registration_facility: facility_1, recorded_at: jan_2019)
      create(:patient, :hypertension_and_diabetes, registration_facility: facility_1, recorded_at: feb_2019)

      create(:patient, :diabetes, registration_facility: facility_2, recorded_at: jan_2019)
      create(:patient, :hypertension, registration_facility: facility_2, recorded_at: jan_2019)
      create(:patient, :hypertension_and_diabetes, registration_facility: facility_2, recorded_at: jan_2019)
      create(:patient, :hypertension_and_diabetes, registration_facility: facility_2, recorded_at: feb_2019)
      create(:patient, :hypertension_and_diabetes, registration_facility: facility_2, recorded_at: mar_2019)

      refresh_views

      schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_1.region.slug][("Jan 2019".to_period)]).to eq(1)
      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_1.region.slug][("Feb 2019".to_period)]).to eq(1)
      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_1.region.slug][("Mar 2019".to_period)]).to eq(0)

      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_1.region.slug][("Jan 2019".to_period)]).to eq(1)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_1.region.slug][("Feb 2019".to_period)]).to eq(2)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_1.region.slug][("Mar 2019".to_period)]).to eq(2)

      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_2.region.slug][("Jan 2019".to_period)]).to eq(1)
      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_2.region.slug][("Feb 2019".to_period)]).to eq(1)
      expect(schema.monthly_hypertension_and_diabetes_registrations[facility_2.region.slug][("Mar 2019".to_period)]).to eq(1)

      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_2.region.slug][("Jan 2019".to_period)]).to eq(1)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_2.region.slug][("Feb 2019".to_period)]).to eq(2)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[facility_2.region.slug][("Mar 2019".to_period)]).to eq(3)

      expect(schema.monthly_hypertension_and_diabetes_registrations[region.slug][("Jan 2019".to_period)]).to eq(2)
      expect(schema.monthly_hypertension_and_diabetes_registrations[region.slug][("Feb 2019".to_period)]).to eq(2)
      expect(schema.monthly_hypertension_and_diabetes_registrations[region.slug][("Mar 2019".to_period)]).to eq(1)

      expect(schema.cumulative_hypertension_and_diabetes_registrations[region.slug][("Jan 2019".to_period)]).to eq(2)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[region.slug][("Feb 2019".to_period)]).to eq(4)
      expect(schema.cumulative_hypertension_and_diabetes_registrations[region.slug][("Mar 2019".to_period)]).to eq(5)
    end
  end

  describe "overdue hypertension patients" do
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
    let(:range) { (24.months.ago.to_period..this_month.to_period) }
    let(:views) {
      %w[ Reports::Month
        Reports::Facility
        Reports::PatientVisit
        Reports::PatientState
        Reports::OverduePatient
        Reports::FacilityState].freeze
    }

    describe "#patients_returned_after_call_rates" do
      it "returns the percentage of overdue patients who returned to care after getting a call" do
        facility_1_patients = create_list(:patient, 5, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 27.days)

        facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.patients_returned_after_call_rates[facility_1.region.slug]
        facility_2_results = schema.patients_returned_after_call_rates[facility_2.region.slug]
        region_results = schema.patients_returned_after_call_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 0
        expect(facility_1_results[two_months_ago.to_period]).to eq 100
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 50
        expect(region_results[two_months_ago.to_period]).to eq 100

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#contactable_patients_returned_after_call_rates" do
      it "returns the percentage of contactable overdue patients who returned to care after getting a call" do
        facility_1_contactable_patients = create_list(:patient, 3, :with_sanitized_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        facility_1_patients_without_phone = create_list(:patient, 2, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, patient: facility_1_contactable_patients.first, device_created_at: this_month)
        create(:call_result, patient: facility_1_contactable_patients.second, device_created_at: this_month)
        create(:call_result, patient: facility_1_contactable_patients.third, device_created_at: one_month_ago + 12.day)
        create(:call_result, patient: facility_1_patients_without_phone.first, device_created_at: one_month_ago + 12.day)
        create(:call_result, patient: facility_1_patients_without_phone.second, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_contactable_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_contactable_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_contactable_patients.third, device_created_at: one_month_ago + 13.days)
        create(:blood_pressure, patient: facility_1_patients_without_phone.second, device_created_at: two_months_ago + 27.days)

        facility_2_contactable_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        facility_2_patient_without_phone = create(:patient, :without_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)

        create(:call_result, patient: facility_2_contactable_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, patient: facility_2_contactable_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, patient: facility_2_contactable_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)
        create(:call_result, patient: facility_2_patient_without_phone, device_created_at: this_month)

        create(:blood_pressure, patient: facility_2_contactable_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_contactable_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_contactable_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)
        create(:blood_pressure, patient: facility_2_patient_without_phone, device_created_at: this_month + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.contactable_patients_returned_after_call_rates[facility_1.region.slug]
        facility_2_results = schema.contactable_patients_returned_after_call_rates[facility_2.region.slug]
        region_results = schema.contactable_patients_returned_after_call_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 50
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 0
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 75
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 0

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#patients_returned_with_result_agreed_to_visit_rates" do
      it "returns the percentage of overdue patients who returned to care who agreed to visit" do
        facility_1_patients = create_list(:patient, 5, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.patients_returned_with_result_agreed_to_visit_rates[facility_1.region.slug]
        facility_2_results = schema.patients_returned_with_result_agreed_to_visit_rates[facility_2.region.slug]
        region_results = schema.patients_returned_with_result_agreed_to_visit_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 100
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 100

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#contactable_patients_returned_with_result_agreed_to_visit_rates" do
      it "returns the percentage of contactable overdue patients who returned to care who agreed to visit" do
        facility_1_patients = create_list(:patient, 5, :with_sanitized_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_sanitized_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, result_type: :agreed_to_visit, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.contactable_patients_returned_with_result_agreed_to_visit_rates[facility_1.region.slug]
        facility_2_results = schema.contactable_patients_returned_with_result_agreed_to_visit_rates[facility_2.region.slug]
        region_results = schema.contactable_patients_returned_with_result_agreed_to_visit_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 0
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 0

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#patients_returned_with_result_remind_to_call_later_rates" do
      it "returns the percentage of overdue patients who returned to care who needs to be called again later" do
        facility_1_patients = create_list(:patient, 5, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.patients_returned_with_result_remind_to_call_later_rates[facility_1.region.slug]
        facility_2_results = schema.patients_returned_with_result_remind_to_call_later_rates[facility_2.region.slug]
        region_results = schema.patients_returned_with_result_remind_to_call_later_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 100
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 100

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#contactable_patients_returned_with_result_remind_to_call_later_rates" do
      it "returns the percentage of contactable overdue patients who returned to care who needs to be called again later" do
        facility_1_patients = create_list(:patient, 5, :with_sanitized_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_sanitized_phone_number, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, result_type: :remind_to_call_later, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.contactable_patients_returned_with_result_remind_to_call_later_rates[facility_1.region.slug]
        facility_2_results = schema.contactable_patients_returned_with_result_remind_to_call_later_rates[facility_2.region.slug]
        region_results = schema.contactable_patients_returned_with_result_remind_to_call_later_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 0
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 0

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#patients_returned_with_result_removed_from_list_rates" do
      it "returns the percentage of overdue patients who returned to care who were removed from list" do
        facility_1_patients = create_list(:patient, 5, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.patients_returned_with_result_removed_from_list_rates[facility_1.region.slug]
        facility_2_results = schema.patients_returned_with_result_removed_from_list_rates[facility_2.region.slug]
        region_results = schema.patients_returned_with_result_removed_from_list_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 100
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 100

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end

    describe "#contactable_patients_returned_with_result_removed_from_list_rates" do
      it "returns the percentage of contactable overdue patients who returned to care who were removed from list" do
        facility_1_patients = create_list(:patient, 5, :with_overdue_appointments, :hypertension, assigned_facility: facility_1, recorded_at: five_months_ago)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.first, device_created_at: this_month)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.second, device_created_at: this_month)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.third, device_created_at: this_month + 12.day)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 12.day)
        create(:call_result, :remove_from_overdue_list, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 12.day)

        create(:blood_pressure, patient: facility_1_patients.first, device_created_at: this_month + 15.days)
        create(:blood_pressure, patient: facility_1_patients.second, device_created_at: this_month + 16.days)
        create(:blood_pressure, patient: facility_1_patients.third, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_1_patients.fourth, device_created_at: one_month_ago + 14.days)
        create(:blood_pressure, patient: facility_1_patients.fifth, device_created_at: two_months_ago + 14.days)

        facility_2_patients = create_list(:patient, 3, :with_overdue_appointments, :hypertension, assigned_facility: facility_2, recorded_at: five_months_ago)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.first, device_created_at: this_month + 12.days)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.second, device_created_at: this_month + 3.days)
        create(:call_result, :remove_from_overdue_list, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day)

        create(:blood_pressure, patient: facility_2_patients.first, device_created_at: this_month + 27.days)
        create(:blood_pressure, patient: facility_2_patients.second, device_created_at: this_month + 18.days)
        create(:blood_pressure, patient: facility_2_patients.third, device_created_at: one_month_ago.end_of_month.beginning_of_day + 15.days)

        RefreshReportingViews.new(views: views).call

        schema = described_class.new([facility_1.region, facility_2.region, region], periods: range)

        facility_1_results = schema.contactable_patients_returned_with_result_removed_from_list_rates[facility_1.region.slug]
        facility_2_results = schema.contactable_patients_returned_with_result_removed_from_list_rates[facility_2.region.slug]
        region_results = schema.contactable_patients_returned_with_result_removed_from_list_rates[region.slug]

        expect(facility_1_results[this_month.to_period]).to eq 67
        expect(facility_1_results[one_month_ago.to_period]).to eq 100
        expect(facility_1_results[two_months_ago.to_period]).to eq 100
        expect(facility_2_results[this_month.to_period]).to eq 100
        expect(facility_2_results[one_month_ago.to_period]).to eq 100
        expect(facility_2_results[two_months_ago.to_period]).to eq 0
        expect(region_results[this_month.to_period]).to eq 80
        expect(region_results[one_month_ago.to_period]).to eq 100
        expect(region_results[two_months_ago.to_period]).to eq 100

        periods_before_three_months = five_months_ago.to_period..three_months_ago.to_period
        periods_before_three_months.each do |period|
          expect(facility_1_results[period]).to eq 0
          expect(facility_2_results[period]).to eq 0
          expect(region_results[period]).to eq 0
        end
      end
    end
  end
end
