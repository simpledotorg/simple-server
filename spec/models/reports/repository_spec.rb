require "rails_helper"

RSpec.describe Reports::Repository, type: :model do
  using StringToPeriod

  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:user_2) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:july_2020_range) { (Period.month(july_2020.advance(months: -24))..Period.month(july_2020)) }

  let(:june_1_2018) { Time.zone.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.zone.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.zone.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.zone.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.zone.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.zone.parse("January 1st, 2020 00:00:00+00:00") }
  let(:jan_2020_period) { jan_2020.to_period }
  let(:july_2018) { Time.zone.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_2020) { Time.zone.parse("July 1st, 2020 00:00:00+00:00") }

  around do |example|
    with_reporting_time_zone { example.run }
  end

  context "earliest patient record" do
    it "returns the earliest between assigned, registered, and follow up" do
      facility_1, facility_2, facility_3 = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1)
      district_region = facility_group_1.region
      other_facility = create(:facility)
      region_with_no_patients = create(:facility).region

      _patient_1 = create(:patient, recorded_at: july_2018, assigned_facility: facility_2, registration_user: user)
      _patient_2 = create(:patient, recorded_at: june_1_2018, assigned_facility: other_facility, registration_facility: facility_1, registration_user: user)
      follow_up_patient = create(:patient, recorded_at: july_2018, assigned_facility: other_facility, registration_user: user)
      create(:blood_pressure, patient: follow_up_patient, facility: facility_3, recorded_at: june_30_2020, user: user)

      refresh_views

      regions = [district_region, region_with_no_patients, facility_1.region, facility_3.region]
      repo = Reports::Repository.new(regions, periods: jan_2019.to_period)
      expect(repo.earliest_patient_recorded_at[district_region.slug]).to eq(june_1_2018.to_date)
      expect(repo.earliest_patient_recorded_at[facility_1.region.slug]).to eq(june_1_2018.to_date)
      expect(repo.earliest_patient_recorded_at[region_with_no_patients.slug]).to be_nil
      expect(repo.earliest_patient_recorded_at[facility_3.slug]).to eq(june_30_2020.to_period.to_date)
    end
  end

  context "counts and rates" do
    it "gets assigned and registration counts for single facility region" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1, facility_2 = facilities.take(2)

      default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
      _facility_1_registered = create_list(:patient, 2, default_attrs.merge(full_name: "controlled", recorded_at: jan_2019 + 1.day))
      create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019.advance(months: -4), assigned_facility: facility_1, registration_user: user)
      _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

      refresh_views

      repo = described_class.new(facility_1.region, periods: jan_2019.to_period)
      expected = {
        facility_1.slug => {
          jan_2019.to_period => 2
        }
      }
      expect(repo.monthly_registrations).to eq(expected)
    end

    it "gets assigned and registration counts for single facility_group region" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1, facility_2 = facilities.take(2)
      facility_in_other_district = create(:facility)

      Timecop.freeze("January 1st 2019 05:30:30 IST") do
        _patient_registered_in_facility_1 = create(:patient, assigned_facility: facility_in_other_district, registration_facility: facility_1)
        _patient_assigned_to_facility_1 = create(:patient, assigned_facility: facility_1, registration_facility: facility_in_other_district)
        _patient_registered_and_assigned_to_facility_2 = create(:patient, assigned_facility: facility_2, registration_facility: facility_2)
        _patient_outside_facility_group = create(:patient, registration_facility: facility_in_other_district)
      end
      region = facility_group_1.region

      refresh_views

      range = jan_2019.to_period..("June 2019".to_period)
      repo = described_class.new(region, periods: range)
      expected_registered = {
        facility_group_1.slug => {
          jan_2019.to_period => 2,
          "Feb 2019".to_period => 0,
          "March 2019".to_period => 0,
          "April 2019".to_period => 0,
          "May 2019".to_period => 0,
          "June 2019".to_period => 0
        }
      }
      expect(repo.monthly_registrations).to eq(expected_registered)
      expect(repo.adjusted_patients_without_ltfu[region.slug][Period.month("April 1st 2019")]).to eq(2)
    end

    it "gets assigned and registration counts for a range of periods" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1, facility_2 = facilities.take(2)

      default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
      _facility_1_registered_in_jan_2019 = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_2019))
      _facility_1_registered_in_august_2018 = create_list(:patient, 2, default_attrs.merge(recorded_at: "August 1st 2018 00:00 UTC"))
      _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

      refresh_views

      slug = facility_1.slug
      repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))

      expect(repo.cumulative_assigned_patients[slug][Period.month("August 2018")]).to eq(2)
      expect(repo.cumulative_assigned_patients[slug][Period.month("Jan 2019")]).to eq(4)
      expect(repo.monthly_registrations[slug][Period.month("August 2018")]).to eq(2)
      expect(repo.monthly_registrations[slug][Period.month("Jan 2019")]).to eq(2)
      expect(repo.monthly_registrations[slug][july_2020.to_period]).to eq(0)
    end

    it "can count registrations and cumulative registrations by user" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1 = facilities.first
      user_2 = create(:user)

      default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
      jan_1_2018 = Period.month("January 1 2018")
      _facility_1_registered_before_repository_range = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_1_2018.value))
      _facility_1_registered_in_jan_2019 = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_2019))
      _facility_1_registered_in_august_2018 = create_list(:patient, 2, default_attrs.merge(recorded_at: Time.zone.parse("August 10th 2018")))
      _user_2_registered = create(:patient, full_name: "other user", recorded_at: jan_2019, registration_facility: facility_1, registration_user: user_2)

      refresh_views

      repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))
      expect(repo.monthly_registrations_by_user[facility_1.slug][jan_2019.to_period][user.id]).to eq(2)
      expect(repo.monthly_registrations_by_user[facility_1.slug][jan_2019.to_period][user_2.id]).to eq(1)
      expect(repo.monthly_registrations_by_user[facility_1.slug][july_2020.to_period]).to be_nil
    end

    it "can count diabetes registrations and cumulative diabetes registrations by user" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1 = facilities.first
      user_2 = create(:user)

      default_attrs = {registration_facility: facility_1, assigned_facility: facility_1, registration_user: user}
      jan_1_2018 = Period.month("January 1 2018")
      _facility_1_registered_before_repository_range = create_list(:patient, 2, :diabetes, default_attrs.merge(recorded_at: jan_1_2018.value))
      _facility_1_registered_in_jan_2019 = create_list(:patient, 2, :diabetes, default_attrs.merge(recorded_at: jan_2019))
      _facility_1_registered_in_august_2018 = create_list(:patient, 2, :diabetes, default_attrs.merge(recorded_at: Time.zone.parse("August 10th 2018")))
      _user_2_registered = create(:patient, :diabetes, full_name: "other user", recorded_at: jan_2019, registration_facility: facility_1, registration_user: user_2)

      refresh_views

      repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))
      expect(repo.monthly_registrations_by_user(diagnosis: :diabetes)[facility_1.slug][jan_2019.to_period][user.id]).to eq(2)
      expect(repo.monthly_registrations_by_user(diagnosis: :diabetes)[facility_1.slug][jan_2019.to_period][user_2.id]).to eq(1)
      expect(repo.monthly_registrations_by_user(diagnosis: :diabetes)[facility_1.slug][july_2020.to_period]).to be_nil
    end

    it "can count overdue patients called by user" do
      timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
      this_month = timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0)
      one_month_ago = this_month - 1.months
      two_months_ago = this_month - 2.months
      three_months_ago = this_month - 3.months

      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility = facilities.first
      user_1 = create(:user, registration_facility: facility)
      user_2 = create(:user, registration_facility: facility)

      patient_1 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)
      patient_2 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)
      patient_3 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)
      patient_4 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)

      create(:call_result, user: user_1, facility: facility, patient: patient_1, device_created_at: this_month)
      create(:call_result, user: user_2, facility: facility, patient: patient_2, device_created_at: this_month)
      create(:call_result, user: user_1, facility: facility, patient: patient_3, device_created_at: one_month_ago)
      create(:call_result, user: user_2, facility: facility, patient: patient_4, device_created_at: two_months_ago)

      refresh_views

      repo = Reports::Repository.new(facility.region, periods: (two_months_ago.to_period..this_month.to_period))
      expect(repo.overdue_patients_called_by_user[facility.slug][this_month.to_period][user_1.id]).to eq(1)
      expect(repo.overdue_patients_called_by_user[facility.slug][one_month_ago.to_period][user_1.id]).to eq(1)
      expect(repo.overdue_patients_called_by_user[facility.slug][this_month.to_period][user_2.id]).to eq(1)
      expect(repo.overdue_patients_called_by_user[facility.slug][two_months_ago.to_period][user_2.id]).to eq(1)
      expect(repo.overdue_patients_called_by_user[facility.slug][three_months_ago.to_period]).to be_nil
    end

    it "can count contactable overdue patients called by user" do
      timezone = Time.find_zone(Period::REPORTING_TIME_ZONE)
      this_month = timezone.local(Date.today.year, Date.today.month, 1, 0, 0, 0)
      one_month_ago = this_month - 1.months
      two_months_ago = this_month - 2.months
      three_months_ago = this_month - 3.months

      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility = facilities.first
      user_1 = create(:user, registration_facility: facility)
      user_2 = create(:user, registration_facility: facility)

      patient_1 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)
      patient_2 = create(:patient, assigned_facility: facility, recorded_at: 10.months.ago)
      # patient with a call result 'removed from list' marked one month ago
      patient_removed_from_list = create(:patient, :removed_from_overdue_list, assigned_facility: facility, recorded_at: 10.months.ago)
      patient_without_phone = create(:patient, :without_phone_number, assigned_facility: facility, recorded_at: 10.months.ago)

      create(:call_result, user: user_1, facility: facility, patient: patient_removed_from_list, device_created_at: this_month)
      create(:call_result, user: user_2, facility: facility, patient: patient_1, device_created_at: this_month)
      create(:call_result, user: user_1, facility: facility, patient: patient_2, device_created_at: one_month_ago)
      create(:call_result, user: user_2, facility: facility, patient: patient_without_phone, device_created_at: two_months_ago)

      refresh_views

      repo = Reports::Repository.new(facility.region, periods: (two_months_ago.to_period..this_month.to_period))
      expect(repo.contactable_overdue_patients_called_by_user[facility.slug][this_month.to_period][user_1.id]).to eq(0)
      expect(repo.contactable_overdue_patients_called_by_user[facility.slug][this_month.to_period][user_2.id]).to eq(1)
      expect(repo.contactable_overdue_patients_called_by_user[facility.slug][one_month_ago.to_period][user_1.id]).to eq(1)
      expect(repo.contactable_overdue_patients_called_by_user[facility.slug][two_months_ago.to_period]).to be_nil
      expect(repo.contactable_overdue_patients_called_by_user[facility.slug][three_months_ago.to_period]).to be_nil
    end

    it "can count registrations and cumulative registrations by gender" do
      facility_1 = FactoryBot.create(:facility, facility_group: facility_group_1)

      default_attrs = {registration_facility: facility_1, assigned_facility: facility_1}
      jan_1_2018 = Period.month("January 1 2018")
      _facility_1_registered_before_repository_range = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_1_2018.value, gender: :female))
      _facility_1_registered_female = create_list(:patient, 3, default_attrs.merge(recorded_at: jan_2019, gender: :female))
      _facility_1_registered_male = create_list(:patient, 2, default_attrs.merge(recorded_at: jan_2019, gender: :male))
      _facility_1_registered_transgender = create_list(:patient, 1, default_attrs.merge(recorded_at: jan_2019, gender: :transgender))

      refresh_views

      repo = Reports::Repository.new(facility_1.region, periods: (july_2018.to_period..july_2020.to_period))
      expect(repo.monthly_registrations_by_gender[facility_1.slug][jan_2019.to_period]["female"]).to eq(3)
      expect(repo.monthly_registrations_by_gender[facility_1.slug][jan_2019.to_period]["male"]).to eq(2)
      expect(repo.monthly_registrations_by_gender[facility_1.slug][jan_2019.to_period]["transgender"]).to eq(1)
    end

    it "can count controlled patients by gender" do
      facility = FactoryBot.create(:facility, facility_group: facility_group_1)

      default_attrs = {registration_facility: facility, assigned_facility: facility, recorded_at: july_2018}
      facility_controlled_male = create_list(:patient, 1, default_attrs.merge(gender: :male))
      facility_controlled_female = create_list(:patient, 2, default_attrs.merge(gender: :female))
      facility_uncontrolled_male = create_list(:patient, 3, default_attrs.merge(gender: :male))
      facility_uncontrolled_female = create_list(:patient, 4, default_attrs.merge(gender: :female))

      facility_controlled_male.each do |patient|
        create(:blood_pressure, :with_encounter, :under_control, recorded_at: jan_2019, patient: patient)
      end

      facility_controlled_female.each do |patient|
        create(:blood_pressure, :with_encounter, :under_control, recorded_at: jan_2019, patient: patient)
      end

      facility_uncontrolled_male.each do |patient|
        create(:blood_pressure, :with_encounter, :hypertensive, recorded_at: jan_2019, patient: patient)
      end

      facility_uncontrolled_female.each do |patient|
        create(:blood_pressure, :with_encounter, :hypertensive, recorded_at: jan_2019, patient: patient)
      end

      refresh_views

      repo = Reports::Repository.new(facility.region, periods: (july_2018.to_period..july_2020.to_period))
      expect(repo.controlled_by_gender[facility.slug][jan_2019.to_period]["male"]).to eq(1)
      expect(repo.controlled_by_gender[facility.slug][jan_2019.to_period]["female"]).to eq(2)
    end

    it "gets registration and assigned patient counts for brand new regions with no data" do
      facility_1 = FactoryBot.create(:facility, facility_group: facility_group_1)
      refresh_views
      slug = facility_1.region.slug
      repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)
      expect(repo.monthly_registrations).to eq({slug => {}})
      expect(repo.controlled).to eq({slug => {}})
      expect(repo.controlled_rates).to eq({slug => {}})
      expect(repo.visited_without_bp_taken).to eq({slug => {}})
      expect(repo.visited_without_bp_taken_rates).to eq({slug => {}})
      expect(repo.visited_without_bp_taken_rates(with_ltfu: true)).to eq({slug => {}})
    end

    it "gets controlled counts and rates for single region" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
      facility_1, facility_2 = facilities.take(2)
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

      expected_counts = {
        facility_1.slug => {
          jan_2020.to_period => 2
        }
      }
      expected_rates = {
        facility_1.slug => {
          jan_2020.to_period => 50
        }
      }
      with_reporting_time_zone do
        repo = Reports::Repository.new(facility_1.region, periods: jan_2020.to_period)
        expect(repo.cumulative_assigned_patients[facility_1.slug][jan_2020.to_period]).to eq(4)
        expect(repo.controlled).to eq(expected_counts)
        expect(repo.controlled_rates).to eq(expected_rates)
      end
    end

    it "gets controlled counts and rates for one month" do
      facility_1, facility_2, facility_3 = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1).sort_by(&:slug)
      facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

      Timecop.freeze(jan_2020) do
        (facility_1_controlled << facility_2_controlled).map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
        end
        facility_1_uncontrolled.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
        end
      end

      refresh_views

      jan = Period.month(jan_2020)
      repo = Reports::Repository.new([facility_1, facility_2, facility_3], periods: Period.month(jan))
      controlled = repo.controlled
      uncontrolled = repo.uncontrolled
      expect(controlled[facility_1.slug][jan]).to eq(2)
      expect(controlled[facility_2.slug][jan]).to eq(1)
      expect(uncontrolled[facility_1.slug][jan]).to eq(2)
      expect(uncontrolled[facility_2.slug][jan]).to eq(0)
    end

    it "returns 0 as a default for periods without any counts" do
      facility_1, facility_2 = *FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
      facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

      Timecop.freeze(jan_2020) do
        facility_1_controlled.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
        end
        facility_1_uncontrolled.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
        end
      end

      refresh_views

      nov_2019_period = Period.month("November 2019")
      repo = Reports::Repository.new([facility_1, facility_2], periods: jan_2020_period)
      expect(repo.controlled[facility_1.slug][nov_2019_period]).to eq(0)
      expect(repo.uncontrolled[facility_1.slug][nov_2019_period]).to eq(0)
      expect(repo.uncontrolled[facility_1.slug][jan_2020_period]).to eq(2)

      expect(repo.controlled[facility_2.slug][nov_2019_period]).to eq(0)
      expect(repo.controlled[facility_2.slug][jan_2020_period]).to eq(0)
      expect(repo.uncontrolled[facility_2.slug]).to eq({})
      expect(repo.uncontrolled[facility_2.slug][nov_2019_period]).to eq(0)
      expect(repo.uncontrolled[facility_2.slug][jan_2020_period]).to eq(0)
    end

    it "gets controlled info for range of month periods" do
      facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1)
      facility_1, facility_2, facility_3 = *facilities.take(3)
      regions = facilities.map(&:region)

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: create(:facility), registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 3.days.from_now, user: user)
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
        end
        uncontrolled_in_jan.map { |patient| create(:bp_with_encounter, :hypertensive, facility: facility_2, patient: patient, recorded_at: 4.days.from_now) }
        create(:bp_with_encounter, :under_control, facility: patient_from_other_facility.assigned_facility, patient: patient_from_other_facility, recorded_at: 4.days.from_now)
      end

      Timecop.freeze(june_1_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago, user: user)
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 35.days.ago, user: user)
        end

        create(:bp_with_encounter, :under_control, facility: facility_3, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

        uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, assigned_facility: facility_1, registration_user: user)
        uncontrolled_in_june.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, recorded_at: 1.days.ago, user: user)
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
        end
      end

      refresh_views

      start_range = july_2020.advance(months: -24)
      range = (Period.month(start_range)..Period.month(july_2020))
      repo = Reports::Repository.new(regions, periods: range)
      result = repo.controlled

      facility_1_results = result[facility_1.slug]
      range.each do |period|
        # Not sure we really care about this behavior
        # expect(facility_1_results[period]).to_not be_nil
      end
      expect(facility_1_results[Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
      expect(facility_1_results[Period.month(june_1_2020)]).to eq(3)
    end

    it "excludes dead patients from control info" do
      facility_1 = FactoryBot.create_list(:facility, 1, facility_group: facility_group_1).first
      facility_1_controlled = create_list(:patient, 1, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      facility_1_controlled_dead = create_list(:patient, 1, status: :dead, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

      Timecop.freeze(jan_2020) do
        facility_1_controlled.concat(facility_1_controlled_dead).map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
        end
      end

      refresh_views
      jan = Period.month(jan_2020)
      repo = Reports::Repository.new(facility_1, periods: Period.month(jan))
      controlled = repo.controlled
      uncontrolled = repo.uncontrolled

      region = facility_1.region
      expect(controlled[region.slug].fetch(jan)).to eq(1)
      expect(uncontrolled[region.slug].fetch(jan)).to eq(0)
    end

    it "gets visit without BP taken counts with and without LTFU" do
      facility_1 = FactoryBot.create_list(:facility, 1, facility_group: facility_group_1).first
      slug = facility_1.region.slug
      # Patient registeres Jan 2019 and has a visit with no BP Jan 2020...so visit w/ no BP _and_ LTFU Jan, Feb, March 2020
      visit_with_no_bp_and_ltfu = create(:patient, full_name: "visit_with_no_bp_and_ltfu", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      create(:appointment, patient: visit_with_no_bp_and_ltfu, recorded_at: jan_2020, facility: facility_1, user: user)
      # This patient registers June 2019, and has a visit with no BP in Sept 2019 and June 2020. They also become LTFU June 2020.
      visit_with_no_bp_and_not_ltfu = create(:patient, full_name: "visit_with_no_bp_and_not_ltfu", recorded_at: "June 2nd 2019", assigned_facility: facility_1, registration_user: user)
      create(:blood_sugar_with_encounter, patient: visit_with_no_bp_and_not_ltfu, recorded_at: "September 1st 2019", facility: facility_1, user: user)
      create(:blood_sugar_with_encounter, patient: visit_with_no_bp_and_not_ltfu, recorded_at: "June 1st 2020", facility: facility_1, user: user)
      # This patient registers June 2019, and has a BP taken every three months in 2020
      visit_with_bp = create(:patient, full_name: "visit_with_bp", recorded_at: "June 1st 2019 00:00:00 UTC", assigned_facility: facility_1, registration_user: user)
      [1, 4, 7, 10].each { |month_num|
        create(:bp_with_encounter, :under_control, recorded_at: "2020-#{month_num}-01 00:00:00 UTC", facility: facility_1, patient: visit_with_bp, user: user)
      }

      refresh_views
      range = (jan_2019.to_period.."Jan 2021".to_period)
      repo = Reports::Repository.new(facility_1, periods: range)

      counts_without_ltfu = repo.visited_without_bp_taken[slug]
      counts_with_ltfu = repo.visited_without_bp_taken(with_ltfu: true)[slug]
      rates_without_ltfu = repo.visited_without_bp_taken_rates[slug]
      rates_with_ltfu = repo.visited_without_bp_taken_rates(with_ltfu: true)[slug]
      ("Jan 2019".to_period.."Aug 2019".to_period).each { |period|
        expect(counts_without_ltfu[period]).to eq(0)
        expect(counts_with_ltfu[period]).to eq(0)
        expect(rates_without_ltfu[period]).to eq(0)
      }
      ("Sep 2019".to_period.."Nov 2019".to_period).each { |period|
        expect(counts_without_ltfu[period]).to eq(1)
        expect(rates_without_ltfu[period]).to eq(33)
      }
      ("June 2020".to_period.."August 2020".to_period).each { |period|
        expect(counts_with_ltfu[period]).to eq(1)
        expect(rates_with_ltfu[period]).to eq(33)
      }
      ("Sept 2020".to_period.."Jan 2021".to_period).each { |period|
        expect(counts_without_ltfu[period]).to eq(0)
        expect(counts_with_ltfu[period]).to eq(0)
      }
    end
  end

  it "returns data for facilities who have no registered / assigned patients" do
    range = ("October 1st 2019".to_period.."January 1st 2020".to_period)
    facility_1 = FactoryBot.create(:facility, name: "Facility 1", block: "block-1", facility_group: facility_group_1)
    facility_2 = FactoryBot.create(:facility, name: "Facility 2", block: "block-1", facility_group: facility_group_1)
    Time.use_zone("UTC") do # ensure we set recorded_at to proper UTC times
      htn_patients = create_list(:patient, 2, full_name: "patient with HTN", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
      range.each do |period|
        htn_patients.each { |p| create(:bp_with_encounter, :under_control, facility: facility_1, patient: p, recorded_at: period.to_date, user: user) }
      end
    end
    refresh_views
    repo = described_class.new(facility_1, periods: range)
    expected = {
      "October 1st 2019" => 2,
      "November 1st 2019" => 2,
      "December 1st 2019" => 2,
      "January 1st, 2020" => 2
    }.transform_keys!(&:to_period)
    expect(repo.hypertension_follow_ups["facility-1"]).to eq(expected)
  end

  it "gets follow ups per facility" do
    facility_1 = FactoryBot.create(:facility, name: "Facility 1", block: "block-1", facility_group: facility_group_1)
    facility_2 = FactoryBot.create(:facility, name: "Facility 2", block: "block-1", facility_group: facility_group_1)
    htn_patients_with_one_follow_up_every_month = create_list(:patient, 2, full_name: "facility 1 patient with HTN", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    htn_patients_with_many_follow_ups_in_one_month = create_list(:patient, 2, full_name: "facility 2 patient with HTN", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
    diabetes_patients = create_list(:patient, 2, :diabetes, full_name: "patient with diabetes", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)

    range = ("October 1st 2019".to_period.."March 1st 2020".to_period)

    range.each do |period|
      diabetes_patients.each { |p| create(:blood_sugar, facility: facility_1, patient: p, recorded_at: period.to_date, user: user) }
      htn_patients_with_one_follow_up_every_month.each { |p| create(:bp_with_encounter, :under_control, facility: facility_1, patient: p, recorded_at: period.to_date, user: user) }
    end
    htn_patients_with_many_follow_ups_in_one_month.each do |p| # all the below should count as _one_ follow up for the month per facility
      create(:appointment, recorded_at: jan_2020, patient: p, facility: facility_1, user: user)
      create(:appointment, recorded_at: jan_2020, patient: p, facility: facility_1, user: user_2)
      create(:blood_sugar_with_encounter, recorded_at: jan_2020.advance(days: 15), patient: p, facility: facility_1, user: user)
      create(:bp_with_encounter, recorded_at: jan_2020.advance(days: 13), patient: p, facility: facility_2, user: user)
      create(:prescription_drug, recorded_at: jan_2020.advance(days: 10), patient: p, facility: facility_1, user: user)
    end

    refresh_views
    expected = {
      "October 1st 2019" => 2,
      "November 1st 2019" => 2,
      "December 1st 2019" => 2,
      "January 1st 2020" => 4,
      "February 1st 2020" => 2,
      "March 1st 2020" => 2
    }.transform_keys!(&:to_period)
    repo = described_class.new(facility_1, periods: range)
    expect(repo.hypertension_follow_ups["facility-1"]).to eq(expected)
  end

  it "returns counts of follow_ups taken per region" do
    facility_1, facility_2 = create_list(:facility, 2)
    create(:patient, registration_facility: facility_1, recorded_at: "February 1st 2021", registration_user: user)
    create(:patient, registration_facility: facility_2, recorded_at: "February 1st 2021", registration_user: user)
    Timecop.freeze("May 10th 2021") do
      periods = (6.months.ago.to_period..1.month.ago.to_period)
      patient_1, patient_2 = create_list(:patient, 2, recorded_at: 10.months.ago)
      user_1 = create(:user)
      user_2 = create(:user)

      # This BP is not a follow up, as it is recorded the same month as the patient registration
      create(:bp_with_encounter, recorded_at: 10.months.ago, facility: facility_1, patient: patient_1, user: user_1)
      # These are all valid follow ups
      create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_2, user: user_2)
      create(:bp_with_encounter, recorded_at: 2.months.ago, facility: facility_1, patient: patient_2, user: user_2)
      create(:bp_with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient_1)
      create(:appointment, recorded_at: 1.month.ago, facility: facility_2, patient: patient_1)
      refresh_views

      repo = described_class.new([facility_1, facility_2], periods: periods)
      repo_2 = described_class.new([facility_1, facility_2], periods: periods)

      expect(repo.hypertension_follow_ups[facility_1.region.slug]).to include({
        Period.month("February 1st 2021") => 2, Period.month("March 1st 2021") => 1
      })
      expect(repo.hypertension_follow_ups[facility_2.region.slug]).to include({Period.month("April 1st 2021") => 1})
      expect(repo_2.hypertension_follow_ups[facility_2.region.slug]).to include({Period.month("April 1st 2021") => 1})
    end
  end

  it "counts distinct follow ups per region / patient" do
    facility_1, facility_2 = create_list(:facility, 2)
    Timecop.freeze("May 10th 2021") do
      create(:patient, registration_facility: facility_1, recorded_at: 6.months.ago)
      periods = (6.months.ago.to_period..1.month.ago.to_period)
      patient_1 = create(:patient, :hypertension, recorded_at: 10.months.ago)
      user_1 = create(:user)
      user_2 = create(:user)

      create(:bp_with_encounter, recorded_at: "February 10th 2021", facility: facility_1, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: "February 11th 2021", facility: facility_1, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: "February 12th 2021", facility: facility_1, patient: patient_1, user: user_2)
      refresh_views

      repo = described_class.new([facility_1, facility_2], periods: periods)

      expect(repo.hypertension_follow_ups[facility_1.region.slug]).to include({
        Period.month("February 1st 2021") => 1
      })
    end
  end

  it "can count by gender" do
    facility_1, facility_2 = create_list(:facility, 2)
    Timecop.freeze("May 10th 2021") do
      periods = (6.months.ago.to_period..1.month.ago.to_period)
      patient_1 = create(:patient, :hypertension, recorded_at: 10.months.ago, gender: :male, registration_facility: facility_1)
      patient_2 = create(:patient, :hypertension, recorded_at: 10.months.ago, gender: :female, registration_facility: facility_2)
      patient_3 = create(:patient, :hypertension, recorded_at: 10.months.ago, gender: :transgender, registration_facility: facility_2)

      create(:bp_with_encounter, recorded_at: "February 10th 2021", facility: facility_1, patient: patient_1)
      create(:bp_with_encounter, recorded_at: "February 11th 2021", facility: facility_1, patient: patient_2)
      create(:bp_with_encounter, recorded_at: "February 12th 2021", facility: facility_1, patient: patient_3)
      refresh_views

      repo = described_class.new([facility_1, facility_2], periods: periods)

      expect(repo.hypertension_follow_ups[facility_1.region.slug]).to include({
        "November 1st 2020".to_period => 0,
        "December 1st 2020".to_period => 0,
        "January 1st 2021".to_period => 0,
        "February 1st 2021".to_period => 3,
        "March 1st 2021".to_period => 0
      })
      expect(repo.hypertension_follow_ups(group_by: :patient_gender)[facility_1.region.slug]).to eq({
        Period.month("February 1st 2021") => {"female" => 1, "male" => 1, "transgender" => 1}
      })
    end
  end

  it "returns counts of BPs taken per user per region" do
    facility_1, facility_2 = create_list(:facility, 2)
    Timecop.freeze("May 10th 2021") do
      periods = (6.months.ago.to_period..1.month.ago.to_period)
      patient_1, patient_2 = create_list(:patient, 2, :hypertension, recorded_at: 10.months.ago)
      user_1 = create(:user)
      user_2 = create(:user)

      # This BP is not a follow up, as it is recorded the same month as the patient registration
      create(:bp_with_encounter, recorded_at: 10.months.ago, facility: facility_1, patient: patient_1, user: user_1)
      # These are all valid follow ups
      create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: 3.months.ago, facility: facility_1, patient: patient_2, user: user_2)
      create(:bp_with_encounter, recorded_at: 2.months.ago, facility: facility_1, patient: patient_2, user: user_2)
      # user_1 records two total follow ups 1 month ago, because they are summed at the patient level
      create(:bp_with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: (1.month.ago + 1.day), facility: facility_2, patient: patient_1, user: user_1)
      create(:bp_with_encounter, recorded_at: 1.month.ago, facility: facility_2, patient: patient_2, user: user_1)
      refresh_views

      repo = described_class.new([facility_1, facility_2], periods: periods)
      facility_1_expected = {
        Period.month("February 1st 2021") => {
          user_1.id => 1,
          user_2.id => 1
        },
        Period.month("March 1st 2021") => {
          user_1.id => 0,
          user_2.id => 1
        }
      }
      facility_2_expected = {
        Period.month("April 1st 2021") => {user_1.id => 2}
      }
      expect(repo.hypertension_follow_ups(group_by: "blood_pressures.user_id")[facility_1.region.slug]).to eq(facility_1_expected)
      expect(repo.hypertension_follow_ups(group_by: "blood_pressures.user_id")[facility_2.region.slug]).to eq(facility_2_expected)
    end
  end

  context "ltfu" do
    it "counts ltfu for patients who never have a BP taken" do
      facility = create(:facility, facility_group: facility_group_1)
      slug = facility.region.slug
      other_facility = create(:facility, facility_group: facility_group_1)
      # patient who never has a BP taken so they are LTFU in Jan 1st 2019
      _ltfu_1 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "Jan 1st 2018 00:00:00 UTC", registration_user: user)
      # patient who becomes LTFU September 2019
      ltfu_2 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "July 1st 2018 00:00:00 UTC", registration_user: user)
      create(:bp_with_encounter, recorded_at: "July 1st 2018 00:00:00", facility: facility, patient: ltfu_2, user: user)
      create(:bp_with_encounter, recorded_at: "September 1st 2018 00:00:00", facility: other_facility, patient: ltfu_2, user: user)
      # patient who is not LTFU
      non_ltfu_patient = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "July 1st 2019 00:00:00 UTC", registration_user: user)
      create(:bp_with_encounter, recorded_at: "July 1st 2019 00:00:00", facility: facility, patient: non_ltfu_patient, user: user)

      refresh_views

      jan_2020_range = (Period.month(jan_2020.advance(months: -24))..Period.month(jan_2020))
      repo = Reports::Repository.new(facility.region, periods: jan_2020_range)
      result = repo.ltfu[slug]
      ("January 2018".to_period.."December 2018".to_period).each { |period| expect(result[period]).to eq(0) }
      ("January 2019".to_period.."August 2019".to_period).each { |period| expect(result[period]).to eq(1) }
      ("September 2019".to_period.."January 2020".to_period).each { |period| expect(result[period]).to eq(2) }
    end
  end

  context "missed visits" do
    it "counts missed visits with and without ltfu" do
      facility = create(:facility, facility_group: facility_group_1)
      slug = facility.region.slug
      # patient who has missed_visit from April 2018 to Dec 2018 and who is LTFU as of Jan 2019
      missed_visit_1 = FactoryBot.create(:patient, assigned_facility: facility, registration_facility: facility, recorded_at: "Jan 1st 2018 08:00:00 UTC", registration_user: user)
      create(:bp_with_encounter, :under_control, facility: facility, patient: missed_visit_1, recorded_at: "Jan 1st 2018 08:00:00 UTC")

      # patient who has missed_visit from April 2018 to Dec 2018 and who is LTFU from Jan 2019 until
      # April 2019 when they get a BP taken. They are then missed_visit again starting in July 2019.
      missed_visit_2 = FactoryBot.create(:patient, assigned_facility: facility, recorded_at: "Jan 1st 2018 00:00:00 UTC", registration_user: user)
      create(:bp_with_encounter, :under_control, facility: facility, patient: missed_visit_2, recorded_at: "April 1st 2019 23:59:00 UTC")

      refresh_views

      jan_2020_range = (Period.month(jan_2020.advance(months: -24))..Period.month(jan_2020))
      repo = Reports::Repository.new(facility.region, periods: jan_2020_range)
      result_without_ltfu = repo.missed_visits_without_ltfu[slug]
      result_with_ltfu = repo.missed_visits_with_ltfu[slug]

      ("Jan 2018".to_period.."Mar 2018".to_period).each { |period|
        expect(result_without_ltfu[period]).to eq(0)
        expect(result_with_ltfu[period]).to eq(0)
      }
      ("Apr 2018".to_period.."December 2018".to_period).each { |period|
        expect(result_without_ltfu[period]).to eq(2)
        expect(result_with_ltfu[period]).to eq(2)
      }
      ("Jan 2019".to_period.."March 2019".to_period).each { |period|
        expect(result_without_ltfu[period]).to eq(0)
        expect(result_with_ltfu[period]).to eq(2)
      }
      ("Apr 2019".to_period.."June 2019".to_period).each { |period|
        expect(result_without_ltfu[period]).to eq(0)
        expect(result_with_ltfu[period]).to eq(1)
      }
      ("July 2019".to_period.."Jan 2020".to_period).each { |period|
        expect(result_without_ltfu[period]).to eq(1)
        expect(result_with_ltfu[period]).to eq(2)
      }
    end
  end

  context "caching" do
    let(:facility_1) { create(:facility, name: "facility-1") }

    it "creates cache keys" do
      repo = Reports::Repository.new(facility_1, periods: Period.month("June 1 2019")..Period.month("Jan 1 2020"))
      refresh_views
      cache_keys = repo.schema.send(:cache_entries, :controlled_rates).map(&:cache_key)
      cache_keys.each do |key|
        expect(key).to include("controlled_rates")
      end
    end

    it "memoizes calls to queries" do
      controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      Timecop.freeze(jan_2020) do
        controlled_in_jan.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
        end
      end
      refresh_views

      repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)

      allow(repo.schema).to receive(:region_period_cached_query).and_call_original
      expect(repo.schema).to receive(:region_period_cached_query).with(:controlled_rates, with_ltfu: false).exactly(1).times.and_call_original

      3.times { _result = repo.controlled_rates }
    end

    it "will not ignore memoization when bust_cache is true" do
      controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
      Timecop.freeze(jan_2020) do
        controlled_in_jan.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 4.days.from_now, user: user)
        end
      end
      refresh_views

      RequestStore[:bust_cache] = true
      repo = Reports::Repository.new(facility_1.region, periods: july_2020_range)
      expect(repo.schema).to receive(:region_period_cached_query).with(:controlled_rates, with_ltfu: false).exactly(1).times

      3.times { _result = repo.controlled_rates }
    end
  end

  context "legacy control specs" do
    it "works for very old dates" do
      facility_1 = create(:facility)
      patient = create(:patient, registration_facility: facility_1, recorded_at: jan_2020.advance(months: -4))
      create(:bp_with_encounter, :under_control, recorded_at: jan_2020.advance(months: -1), patient: patient, facility: facility_1)
      refresh_views

      ten_years_ago = patient.recorded_at.advance(years: -10).to_period
      range = ten_years_ago..(ten_years_ago.advance(months: 12))
      repo = Reports::Repository.new(facility_1, periods: range)

      expect(repo.adjusted_patients[facility_1.slug]).to eq({})
      # cumulative registrations returns all summed registrations for all months we have in reporting_months...
      # not sure who should be responsible for trimming the result set
      expect(repo.cumulative_registrations[facility_1.slug]).to eq({})
    end
  end

  context "constant values" do
    it "returns delegated counts" do
      expected_keys = [
        :adjusted_patients_with_ltfu,
        :adjusted_patients_without_ltfu,
        :assigned_patients,
        :complete_monthly_registrations,
        :controlled,
        :cumulative_assigned_patients,
        :cumulative_registrations,
        :cumulative_assigned_diabetic_patients,
        :cumulative_diabetes_registrations,
        :cumulative_hypertension_and_diabetes_registrations,
        :earliest_patient_recorded_at,
        :earliest_patient_recorded_at_period,
        :under_care, :diabetes_under_care,
        :ltfu, :diabetes_ltfu,
        :missed_visits,
        :missed_visits_with_ltfu,
        :missed_visits_without_ltfu,
        :monthly_registrations,
        :monthly_diabetes_registrations,
        :monthly_hypertension_and_diabetes_registrations,
        :uncontrolled, :visited_without_bp_taken,
        :monthly_overdue_calls,
        :monthly_diabetes_followups,
        :total_appts_scheduled,
        :appts_scheduled_0_to_14_days,
        :appts_scheduled_15_to_31_days,
        :appts_scheduled_32_to_62_days,
        :appts_scheduled_more_than_62_days,
        :adjusted_diabetes_patients_without_ltfu,
        :adjusted_diabetes_patients_with_ltfu,
        :adjusted_diabetes_patients,
        :bs_below_200_patients,
        :bs_below_200_patients_fasting_and_hba1c,
        :bs_200_to_300_patients,
        :bs_over_300_patients,
        :diabetes_missed_visits,
        :visited_without_bs_taken,
        :diabetes_patients_with_bs_taken,
        :diabetes_total_appts_scheduled,
        :diabetes_appts_scheduled_0_to_14_days,
        :diabetes_appts_scheduled_15_to_31_days,
        :diabetes_appts_scheduled_32_to_62_days,
        :diabetes_appts_scheduled_more_than_62_days,
        :dead, :diabetes_dead,
        :under_care,
        :diabetes_under_care,
        :overdue_patients,
        :contactable_overdue_patients,
        :patients_called, :contactable_patients_called,
        :patients_called_with_result_agreed_to_visit,
        :patients_called_with_result_remind_to_call_later,
        :patients_called_with_result_removed_from_list,
        :contactable_patients_called_with_result_agreed_to_visit,
        :contactable_patients_called_with_result_remind_to_call_later,
        :contactable_patients_called_with_result_removed_from_list,
        :patients_returned_after_call,
        :patients_returned_with_result_agreed_to_visit,
        :patients_returned_with_result_remind_to_call_later,
        :patients_returned_with_result_removed_from_list,
        :contactable_patients_returned_after_call,
        :contactable_patients_returned_with_result_agreed_to_visit,
        :contactable_patients_returned_with_result_remind_to_call_later,
        :contactable_patients_returned_with_result_removed_from_list,
        :bs_200_to_300_patients_fasting_and_hba1c,
        :bs_over_300_patients_fasting_and_hba1c
      ]
      expect(described_class::DELEGATED_COUNTS).to match_array(expected_keys)
    end

    it "returns delegated rates" do
      expected_keys = [
        :controlled_rates,
        :ltfu_rates,
        :diabetes_ltfu_rates,
        :missed_visits_rate,
        :missed_visits_with_ltfu_rates,
        :missed_visits_without_ltfu_rates,
        :uncontrolled_rates,
        :visited_without_bp_taken_rates,
        :appts_scheduled_0_to_14_days_rates,
        :appts_scheduled_15_to_31_days_rates,
        :appts_scheduled_32_to_62_days_rates,
        :appts_scheduled_more_than_62_days_rates,
        :bs_below_200_rates,
        :bs_below_200_rates_fasting_and_hba1c,
        :bs_200_to_300_rates,
        :bs_200_to_300_rates_fasting_and_hba1c,
        :bs_over_300_rates,
        :bs_over_300_rates_fasting_and_hba1c,
        :diabetes_missed_visits_rates,
        :visited_without_bs_taken_rates,
        :diabetes_appts_scheduled_0_to_14_days_rates,
        :diabetes_appts_scheduled_15_to_31_days_rates,
        :diabetes_appts_scheduled_32_to_62_days_rates,
        :diabetes_appts_scheduled_more_than_62_days_rates,
        :overdue_patients_rates,
        :contactable_overdue_patients_rates,
        :patients_called_rates,
        :contactable_patients_called_rates,
        :patients_called_with_result_agreed_to_visit_rates,
        :patients_called_with_result_remind_to_call_later_rates,
        :patients_called_with_result_removed_from_list_rates,
        :contactable_patients_called_with_result_agreed_to_visit_rates,
        :contactable_patients_called_with_result_remind_to_call_later_rates,
        :contactable_patients_called_with_result_removed_from_list_rates,
        :patients_returned_after_call_rates,
        :patients_returned_with_result_agreed_to_visit_rates,
        :patients_returned_with_result_remind_to_call_later_rates,
        :patients_returned_with_result_removed_from_list_rates,
        :contactable_patients_returned_after_call_rates,
        :contactable_patients_returned_with_result_agreed_to_visit_rates,
        :contactable_patients_returned_with_result_remind_to_call_later_rates,
        :contactable_patients_returned_with_result_removed_from_list_rates
      ]
      expect(described_class::DELEGATED_RATES).to match_array(expected_keys)
    end
  end
end
