require "rails_helper"

RSpec.describe Reports::RegionService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:jan_2019) { Time.parse("January 1st, 2019 12:00 IST") }
  let(:jan_2020) { Time.parse("January 1st, 2020 12:00 IST") }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }

  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_1_2019) { Time.parse("July 1st, 2019") }
  let(:july_2020) { Time.parse("July 1st, 2020") }

  def refresh_views
    RefreshReportingViews.call
  end

  it "sets the period" do
    period = Period.month(june_1_2020)
    service = Reports::RegionService.new(region: facility_group_1, period: period)
    Timecop.freeze("June 30 2020 5:00 PM EST") do
      expect(service.period.value).to eq(june_1_2020.to_date)
    end
  end

  it "counts registrations and cumulative registrations" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)
    Timecop.freeze("January 1st 2018") do
      create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
    end
    Timecop.freeze("May 30th 2018") do
      create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
    end
    Timecop.freeze(june_1_2018) do
      create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
    end
    Timecop.freeze("April 15th 2020") do
      create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
    end
    Timecop.freeze("May 1 2020") do
      create_list(:patient, 3, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
      create_list(:patient, 1, recorded_at: Time.current, registration_facility: facility, assigned_facility: create(:facility), registration_user: user)
    end

    Timecop.freeze(june_30_2020) do
      create_list(:patient, 4, recorded_at: Time.current, registration_facility: facility, assigned_facility: facility, registration_user: user)
    end

    refresh_views

    result = with_reporting_time_zone do
      Reports::RegionService.call(region: facility_group_1, period: june_1_2020.to_period, months: 26)
    end

    april_period = Date.parse("April 1 2020").to_period
    may_period = Date.parse("May 1 2020").to_period
    june_period = Date.parse("June 1 2020").to_period
    expect(result[:registrations][june_1_2018.to_date.to_period]).to eq(2)
    expect(result[:cumulative_registrations][june_1_2018.to_date.to_period]).to eq(6)
    expect(result[:cumulative_assigned_patients][june_1_2018.to_date.to_period]).to eq(6)
    expect(result[:registrations][april_period]).to eq(2)
    expect(result[:cumulative_registrations][april_period]).to eq(8)
    expect(result[:cumulative_assigned_patients][april_period]).to eq(8)
    expect(result[:registrations][may_period]).to eq(4)
    expect(result[:cumulative_registrations][may_period]).to eq(12)
    expect(result[:cumulative_assigned_patients][may_period]).to eq(11)
    expect(result[:registrations][june_period]).to eq(4)
    expect(result[:cumulative_registrations][june_period]).to eq(16)
    expect(result[:cumulative_assigned_patients][june_period]).to eq(15)
  end

  it "returns control rate for a single facility" do
    facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
    facility = facilities.first

    controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019,
                                          registration_facility: facility, registration_user: user)
    uncontrolled = create_list(:patient, 4, full_name: "uncontrolled", recorded_at: jan_2019,
                                            registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019,
                                                   registration_facility: facilities.last, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled.map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled.map do |patient|
        create(:bp_with_encounter, :hypertensive, facility: facility,
                                                  patient: patient, recorded_at: 4.days.ago, user: user)
      end
      create(:bp_with_encounter, :under_control, facility: facility, patient: patient_from_other_facility,
                                                 recorded_at: 2.days.ago, user: user)
    end

    refresh_views

    service = Reports::RegionService.new(region: facility, period: july_2020.to_period)
    result = service.call

    expect(result[:registrations][Period.month(jan_2019)]).to eq(6)
    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled.size)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(33)
  end

  it "does not include months without registration data" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)
    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
      end
    end

    refresh_views

    result = Timecop.freeze("July 1st 2020") do
      Reports::RegionService.call(region: facility_group_1, period: june_1_2020.to_period)
    end
    expect(result[:cumulative_registrations].size).to eq(4)
    expect(result[:registrations].size).to eq(1)
    expect(result[:controlled_patients].size).to eq(4)
  end

  it "excludes patients registered in the last 3 months" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)

    controlled_jan2020_registration = create(:patient, full_name: "controlled jan2020 registration", recorded_at: jan_2020, registration_facility: facility, registration_user: user)

    Timecop.freeze(jan_2020) do
      create(:bp_with_encounter, :under_control, facility: facility, patient: controlled_jan2020_registration, recorded_at: 2.days.ago)
    end

    refresh_views

    service = Reports::RegionService.new(region: facility_group_1, period: july_2020.to_period)
    result = service.call

    expect(result[:registrations][Period.month(jan_2020)]).to eq(1)
    expect(result[:cumulative_registrations][Period.month(jan_2020)]).to eq(1)
    expect(result[:adjusted_patient_counts][Period.month(jan_2020)]).to eq(0)
    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(0)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(0.0)
  end

  it "excludes patients who are dead or LTFU" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)
    patients = [
      create(:patient, recorded_at: jan_2019, registration_facility: facility, registration_user: user),
      create(:patient, status: :dead, recorded_at: jan_2019, registration_facility: facility, registration_user: user)
    ]

    Timecop.freeze(june_1_2020) do
      patients.each do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    result = Reports::RegionService.new(region: facility_group_1, period: july_2020.to_period).call
    report_month = june_1_2020.to_period

    expect(result[:cumulative_registrations][report_month]).to eq(2)
    expect(result[:cumulative_assigned_patients][report_month]).to eq(1)
    expect(result[:adjusted_patient_counts_with_ltfu][report_month]).to eq(1)
    expect(result[:adjusted_patient_counts][report_month]).to eq(1)
    expect(result[:controlled_patients][report_month]).to eq(1)
    expect(result[:controlled_patients_rate][report_month]).to eq(100.0)
    expect(result[:controlled_patients_with_ltfu_rate][report_month]).to eq(100.0)
    expect(result[:uncontrolled_patients][report_month]).to eq(0)
    expect(result[:uncontrolled_patients_rate][report_month]).to eq(0)
    expect(result[:uncontrolled_patients_with_ltfu_rate][report_month]).to eq(0)
  end

  it "correctly returns controlled patients for past months" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, registration_facility: facility, registration_user: user)
    uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, registration_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, registration_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled_in_jan.map { |patient| create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago) }
      create(:bp_with_encounter, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    Timecop.freeze(june_1_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
        create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 35.days.ago, user: user)
      end

      create(:bp_with_encounter, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

      # register 5 more patients in feb 2020
      uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, registration_facility: facility, registration_user: user)
      uncontrolled_in_june.map do |patient|
        create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago, user: user)
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    result = with_reporting_time_zone do
      Reports::RegionService.call(region: facility_group_1, period: july_2020.to_period)
    end

    expect(result[:registrations][Period.month(jan_2019)]).to eq(5)
    expect(result[:cumulative_registrations][Period.month(jan_2019)]).to eq(5)
    expect(result[:cumulative_assigned_patients][Period.month(jan_2019)]).to eq(5)
    expect(result[:adjusted_patient_counts][Period.month(jan_2019)]).to eq(0)

    expect(result[:cumulative_registrations][Period.month(jan_2020)]).to eq(5)
    expect(result[:cumulative_assigned_patients][Period.month(jan_2020)]).to eq(5)
    expect(result[:adjusted_patient_counts][Period.month(jan_2020)]).to eq(4)
    expect(result[:adjusted_patient_counts_with_ltfu][Period.month(jan_2020)]).to eq(5)
    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(50.0)
    expect(result[:controlled_patients_with_ltfu_rate][Period.month(jan_2020)]).to eq(40.0)

    # 3 controlled patients in june and 10 cumulative registered patients
    expect(result[:cumulative_registrations][Period.month(june_1_2020)]).to eq(10)
    expect(result[:cumulative_assigned_patients][Period.month(june_1_2020)]).to eq(10)
    expect(result[:registrations][Period.month(june_1_2020)]).to eq(0)
    expect(result[:controlled_patients][Period.month(june_1_2020)]).to eq(3)
    expect(result[:controlled_patients_rate][Period.month(june_1_2020)]).to eq(30.0)
    expect(result[:uncontrolled_patients][Period.month(june_1_2020)]).to eq(5)
    expect(result[:uncontrolled_patients_rate][Period.month(june_1_2020)]).to eq(50.0)
  end

  context "visited but no BP taken" do
    it "counts visits for range of periods" do
      may_1 = Time.parse("May 1st, 2020")
      may_15 = Time.parse("May 15th, 2020")
      facility = create(:facility, facility_group: facility_group_1)
      patient_without_bp = FactoryBot.create(:patient, registration_facility: facility, recorded_at: jan_2020)
      patient_with_bp = FactoryBot.create(:patient, registration_facility: facility, recorded_at: jan_2020)
      _appointment_1 = create(:appointment, creation_facility: facility, scheduled_date: may_1, device_created_at: may_1, patient: patient_without_bp)
      _appointment_2 = create(:appointment, creation_facility: facility, scheduled_date: may_15, device_created_at: may_15, patient: patient_with_bp)
      create(:bp_with_encounter, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15)

      service = Reports::RegionService.new(region: facility, period: july_2020.to_period)
      result = service.call
      expect(result[:visited_without_bp_taken][may_1.to_period]).to eq(1)
      expect(result[:visited_without_bp_taken_rates][may_1.to_period]).to eq(50)
    end

    it "counts missed visits for the reporting range _only_" do
      may_1 = Time.parse("May 1st, 2020").end_of_day
      may_15 = Time.parse("May 15th, 2020")
      facility = create(:facility, facility_group: facility_group_1)
      _patient_missed_visit_1 = FactoryBot.create(:patient, registration_facility: facility, recorded_at: Time.parse("December 1st 2010"))
      _patient_missed_visit_2 = FactoryBot.create(:patient, registration_facility: facility, recorded_at: jan_2020)
      patient_without_bp = FactoryBot.create(:patient, registration_facility: facility, recorded_at: jan_2020)
      patient_with_bp = FactoryBot.create(:patient, registration_facility: facility, recorded_at: jan_2020)
      _appointment_1 = create(:appointment, creation_facility: facility, scheduled_date: may_1, device_created_at: may_1, patient: patient_without_bp)
      _appointment_2 = create(:appointment, creation_facility: facility, scheduled_date: may_15, device_created_at: may_15, patient: patient_with_bp)
      create(:bp_with_encounter, :under_control, facility: facility, patient: patient_with_bp, recorded_at: may_15)

      service = Reports::RegionService.new(region: facility, period: july_2020.to_period)
      result = service.call
      expect(result[:missed_visits_with_ltfu].size).to eq(service.range.entries.size)
      expect(result[:missed_visits_with_ltfu][Period.month("August 1 2018")]).to eq(1)
      expect(result[:missed_visits_with_ltfu][jan_2020.to_period]).to eq(1)
      expect(result[:missed_visits_with_ltfu][Period.month("April 1 2020")]).to eq(4)
      expect(result[:missed_visits_with_ltfu][Period.month(may_15)]).to eq(3)

      expect(result[:missed_visits].size).to eq(service.range.entries.size)
      expect(result[:missed_visits][Period.month("August 1 2018")]).to eq(0)
      expect(result[:missed_visits][jan_2020.to_period]).to eq(0)
      expect(result[:missed_visits][Period.month("April 1 2020")]).to eq(3)
    end
  end

  context "districts" do
    it "correctly returns controlled patients from three month window" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first
      facility_2 = create(:facility)

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, registration_facility: facility, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, registration_facility: facility, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, registration_facility: facility_2, registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
        end
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago, user: user)
      end

      Timecop.freeze(june_1_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
        end

        create(:bp_with_encounter, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

        uncontrolled = create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, registration_user: user)
        uncontrolled.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago, user: user)
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        end
      end

      Timecop.freeze(july_2020) do
        refresh_views

        service = Reports::RegionService.new(region: facility_group_1, period: Period.month(july_2020))

        result = service.call

        expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
        june_controlled = controlled_in_jan_and_june << controlled_just_for_june
        expect(result[:controlled_patients][Period.month(june_1_2020)]).to eq(june_controlled.size)
      end
    end

    it "counts adjusted registrations" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first

      _registered_in_jan = create_list(:patient, 2, recorded_at: jan_2019 + 1.day, registration_facility: facility, registration_user: user)

      service = Reports::RegionService.new(region: facility_group_1, period: Period.month(june_1_2020))
      result = service.call
      expect(result.adjusted_patient_counts[Period.month("Jan 2019")]).to eq(0)
      expect(result.adjusted_patient_counts[Period.month("Feb 2019")]).to eq(0)
      expect(result.adjusted_patient_counts[Period.month("Mar 2019")]).to eq(0)
      expect(result.adjusted_patient_counts[Period.month("Apr 2019")]).to eq(2)
      expect(result.adjusted_patient_counts[Period.month("May 2019")]).to eq(2)
    end

    it "returns counts for last n months for controlled patients and registrations" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first

      Timecop.freeze(Time.parse("July 15th 2018")) do
        old_patients = create_list(:patient, 2, recorded_at: 4.months.ago, registration_facility: facility, registration_user: user)
        old_patients.each do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        end
      end

      Timecop.freeze(Time.parse("February 15th 2020")) do
        other_patients = create_list(:patient, 2, recorded_at: 4.months.ago, registration_facility: facility, registration_user: user)
        other_patients.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        end
      end

      Timecop.freeze("April 15th 2020") do
        patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 4.months.ago, registration_facility: facility, registration_user: user)
        patients_with_controlled_bp.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        end
      end

      refresh_views

      service = Reports::RegionService.new(region: facility_group_1, period: Period.month(june_1_2020))
      result = service.call

      expected_controlled_patients = {
        "Jul-2018" => 2, "Aug-2018" => 2, "Sep-2018" => 2,
        "Feb-2020" => 2, "Mar-2020" => 2, "Apr-2020" => 4, "May-2020" => 2, "Jun-2020" => 2
      }
      expected_controlled_patients.default = 0

      expected_cumulative_registrations = {
        "Oct-2019" => 4, "Nov-2019" => 4, "Dec-2019" => 6,
        "Jan-2020" => 6, "Feb-2020" => 6, "Mar-2020" => 6, "Apr-2020" => 6, "May-2020" => 6, "Jun-2020" => 6
      }
      # NOTE: we set the default for the values that are excluded in the hash, otherwise we'd have to enumerate all 24
      # months of data in the hash
      expected_cumulative_registrations.default = 2
      expect(result[:controlled_patients].size).to eq(24)

      result[:controlled_patients].each do |period, count|
        key = period.to_s
        expect(count).to eq(expected_controlled_patients[key]),
          "expected controlled patients #{key} to be #{expected_controlled_patients[key]}, but was #{count}"
      end
      result[:cumulative_registrations].each do |period, count|
        key = period.to_s
        expect(count).to eq(expected_cumulative_registrations[key]),
          "expected cumulative registrations for #{key} to be #{expected_cumulative_registrations[key]}, but was #{count}"
      end
    end
  end

  context "facilities" do
    it "returns control data and registrations" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
      facility, other_facility = facilities.first, facilities.last

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019 + 1.day, registration_facility: facility, registration_user: user)
      uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019 + 1.day, registration_facility: facility, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019 + 1.day, registration_facility: facility, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019 + 1.day, registration_facility: other_facility, registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end
        uncontrolled_in_jan.map { |patient| create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago) }
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
        create(:bp_with_encounter, :under_control, facility: facility, patient: patient_from_other_facility,
                                                   recorded_at: 2.days.ago, user: user)
      end

      Timecop.freeze(june_1_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end

        create(:bp_with_encounter, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago)

        uncontrolled = create_list(:patient, 2, recorded_at: Time.current + 1.day, registration_facility: facility, registration_user: user)
        uncontrolled.map do |patient|
          create(:bp_with_encounter, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago)
          create(:bp_with_encounter, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
        end
      end

      refresh_views

      service = Reports::RegionService.new(region: facility, period: Period.month(july_2020))
      result = service.call

      expect(result[:registrations][jan_2019.to_period]).to eq(5)
      expect(result[:cumulative_registrations][jan_2019.to_period]).to eq(5)
      expect(result[:adjusted_patient_counts][jan_2019.to_period]).to eq(0)

      expect(result[:controlled_patients][jan_2020.to_period]).to eq(2)
      expect(result[:controlled_patients_rate][jan_2020.to_period]).to eq(50.0)
      expect(result[:controlled_patients_with_ltfu_rate][jan_2020.to_period]).to eq(40.0)
      expect(result[:registrations][jan_2020.to_period]).to eq(0)
      expect(result[:cumulative_registrations][jan_2020.to_period]).to eq(5)
      expect(result[:adjusted_patient_counts][jan_2020.to_period]).to eq(4)
      expect(result[:adjusted_patient_counts_with_ltfu][jan_2020.to_period]).to eq(5)

      expect(result[:controlled_patients][june_1_2020.to_period]).to eq(3)
      expect(result[:controlled_patients_rate][june_1_2020.to_period]).to eq(60.0)
      expect(result[:registrations][june_1_2020.to_period]).to eq(2)
      expect(result[:cumulative_registrations][june_1_2020.to_period]).to eq(7)
      expect(result[:adjusted_patient_counts][june_1_2020.to_period]).to eq(5)
    end
  end

  context "without months_request" do
    it "returns data for the default limit of 24 months " do
      facility = create(:facility, facility_group: facility_group_1)
      ("January 1st 2018".to_date.to_period..june_1_2020.to_period).each do |period|
        create(:patient, full_name: "registered in #{period}", recorded_at: period.value, registration_facility: facility, registration_user: user)
      end

      service = Reports::RegionService.new(region: facility_group_1, period: Period.month(june_1_2020))
      result = service.call
      expect(result[:period_info].count).to eq 24
      expect(result[:registrations].count).to eq 24
    end
  end

  context "with months_request" do
    it "returns data for the requested number of months" do
      month_limit = 6
      facility = create(:facility, facility_group: facility_group_1)
      ("October 1st 2019".to_date.to_period..june_1_2020.to_period).each do |period|
        create(:patient, full_name: "registered in #{period}", recorded_at: period.value, registration_facility: facility, registration_user: user)
      end
      service = Reports::RegionService.new(region: facility_group_1, period: Period.month(june_1_2020), months: month_limit)
      result = service.call
      expect(result[:period_info].count).to eq month_limit
      expect(result[:registrations].count).to eq month_limit
    end
  end
end
