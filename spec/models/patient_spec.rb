require "rails_helper"

describe Patient, type: :model do
  let(:reporting_timezone) { Period::REPORTING_TIME_ZONE }
  def refresh_views
    LatestBloodPressuresPerPatientPerMonth.refresh
  end

  subject(:patient) { build(:patient) }

  it "picks up available genders from country config" do
    expect(described_class::GENDERS).to eq(Rails.application.config.country[:supported_genders])
  end

  describe "factory fixtures" do
    it "can create a valid patient" do
      expect {
        patient = create(:patient)
        expect(patient).to be_valid
      }.to change { Patient.count }.by(1)
        .and change { PatientBusinessIdentifier.count }.by(1)
        .and change { MedicalHistory.count }.by(1)
    end
  end

  describe "Associations" do
    it { is_expected.to have_one(:medical_history) }
    it { is_expected.to have_one(:imo_authorization).optional }

    it { is_expected.to have_many(:phone_numbers) }
    it { is_expected.to have_many(:business_identifiers) }
    it { is_expected.to have_many(:passport_authentications).through(:business_identifiers) }

    it { is_expected.to have_many(:blood_pressures) }
    it { is_expected.to have_many(:blood_sugars) }
    it { is_expected.to have_many(:prescription_drugs) }
    it { is_expected.to have_many(:facilities).through(:blood_pressures) }
    it { is_expected.to have_many(:users).through(:blood_pressures) }
    it { is_expected.to have_many(:appointments) }
    it { is_expected.to have_many(:notifications) }
    it { is_expected.to have_many(:treatment_group_memberships) }
    it { is_expected.to have_many(:treatment_groups).through(:treatment_group_memberships) }
    it { is_expected.to have_many(:experiments).through(:treatment_groups) }
    it { is_expected.to have_many(:teleconsultations) }

    it { is_expected.to have_many(:encounters) }
    it { is_expected.to have_many(:observations).through(:encounters) }

    it { is_expected.to belong_to(:address) }
    it { is_expected.to belong_to(:registration_facility).class_name("Facility").optional }
    it { is_expected.to belong_to(:registration_user).class_name("User") }

    it "has distinct facilities" do
      patient = create(:patient)
      facility = create(:facility)
      create_list(:blood_pressure, 5, :with_encounter, patient: patient, facility: facility)

      expect(patient.facilities.count).to eq(1)
    end

    it { is_expected.to belong_to(:registration_facility).class_name("Facility").optional }
    it { is_expected.to belong_to(:registration_user).class_name("User") }

    it { is_expected.to have_many(:latest_blood_pressures).order(recorded_at: :desc).class_name("BloodPressure") }
    it { is_expected.to have_many(:latest_blood_sugars).order(recorded_at: :desc).class_name("BloodSugar") }

    specify do
      is_expected.to have_many(:current_prescription_drugs)
        .conditions(is_deleted: false)
        .class_name("PrescriptionDrug")
    end

    specify do
      is_expected.to have_many(:latest_scheduled_appointments)
        .conditions(status: "scheduled")
        .order(scheduled_date: :desc)
        .class_name("Appointment")
    end

    specify do
      is_expected.to have_many(:latest_bp_passports)
        .conditions(identifier_type: "simple_bp_passport")
        .order(device_created_at: :desc)
        .class_name("PatientBusinessIdentifier")
    end
  end

  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"

    it "validates that date of birth is not in the future" do
      patient = build(:patient)
      patient.date_of_birth = 3.days.from_now
      expect(patient).to be_invalid
    end

    it "validates status" do
      patient = Patient.new

      # valid statuses should not cause problems
      patient.status = "active"
      patient.status = "dead"
      patient.status = "migrated"
      patient.status = "unresponsive"
      patient.status = "inactive"

      # invalid statuses should raise errors
      expect { patient.status = "something else" }.to raise_error(ArgumentError)
    end

    it { should validate_presence_of(:status) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "Scopes" do
    describe ".with_diabetes" do
      it "only includes patients with diagnosis of diabetes" do
        dm_patients = create_list(:patient, 2, :diabetes)
        _htn_patients = create(:patient)

        expect(Patient.with_diabetes).to match_array(dm_patients)
      end
    end

    describe ".with_hypertension" do
      it "only includes patients with diagnosis of hypertension" do
        htn_patients = [
          create(:patient),
          create(:patient).tap { |patient| create(:medical_history, :hypertension_yes, patient: patient) }
        ]

        _non_htn_patients = [
          create(:patient, :without_hypertension),
          create(:patient).tap { |patient| patient.medical_history.discard },
          create(:patient).tap { |patient| patient.medical_history.destroy }
        ]

        expect(Patient.with_hypertension).to match_array(htn_patients)
      end
    end

    describe ".not_contacted" do
      let(:patient_to_followup) { create(:patient, device_created_at: 5.days.ago) }
      let(:patient_to_not_followup) { create(:patient, device_created_at: 1.day.ago) }
      let(:patient_contacted) { create(:patient, contacted_by_counsellor: true) }
      let(:patient_could_not_be_contacted) { create(:patient, could_not_contact_reason: "dead") }

      it "includes uncontacted patients registered 2 days ago or earlier" do
        expect(Patient.not_contacted).to include(patient_to_followup)
      end

      it "excludes uncontacted patients registered less than 2 days ago" do
        expect(Patient.not_contacted).not_to include(patient_to_not_followup)
      end

      it "excludes already contacted patients" do
        expect(Patient.not_contacted).not_to include(patient_contacted)
      end

      it "excludes patients who could not be contacted" do
        expect(Patient.not_contacted).not_to include(patient_could_not_be_contacted)
      end
    end

    describe ".for_sync" do
      it "includes discarded patients" do
        discarded_patient = create(:patient, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_patient)
      end

      it "includes nested sync resources" do
        _discarded_patient = create(:patient, deleted_at: Time.now)

        expect(described_class.for_sync.first.association(:address).loaded?).to eq true
        expect(described_class.for_sync.first.association(:phone_numbers).loaded?).to eq true
        expect(described_class.for_sync.first.association(:business_identifiers).loaded?).to eq true
      end
    end

    describe ".ltfu_as_of" do
      it "includes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).to include(ltfu_patient)
      end

      it "excludes patient who is not LTFU because they were registered recently" do
        not_ltfu_patient = Timecop.freeze(6.months.ago) { create(:patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end

      it "excludes patient who is not LTFU because they had a BP recently" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end

      describe "timezone-specific boundaries" do
        it "bp cutoffs for a year ago" do
          # For any provided date in June in the local timezone, the LTFU BP cutoff is the end of June 30 of the
          # previous year in the local timezone.
          #
          # Eg. For any date provided in June 2021, the cutoff is the June 30-Jul 1 boundary of 2020

          long_ago = 5.years.ago

          # We explicitly set the times in the reporting TZ here, but don't use the block helper because its a hassle w/
          # all the local vars we need
          timezone = Time.find_zone(reporting_timezone)
          under_a_year_ago = timezone.local(2020, 7, 1, 0, 0, 1) # Beginning of July 1 2020 in local timezone
          over_a_year_ago = timezone.local(2020, 6, 30, 23, 59, 59) # End of June 30 2020 in local timezone
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: long_ago)
          ltfu_patient = create(:patient, recorded_at: long_ago)

          create(:blood_pressure, patient: not_ltfu_patient, recorded_at: under_a_year_ago)
          create(:blood_pressure, patient: ltfu_patient, recorded_at: over_a_year_ago)
          with_reporting_time_zone do # We don't actually need this, but its a nice sanity check
            refresh_views

            expect(described_class.ltfu_as_of(beginning_of_month)).not_to include(not_ltfu_patient)
            expect(described_class.ltfu_as_of(end_of_month)).not_to include(not_ltfu_patient)

            expect(described_class.ltfu_as_of(beginning_of_month)).to include(ltfu_patient)
            expect(described_class.ltfu_as_of(end_of_month)).to include(ltfu_patient)
          end
        end

        it "bp cutoffs for now" do
          # For any provided date in June in the local timezone, the LTFU BP ending cutoff is the time provided

          long_ago = 5.years.ago
          timezone = Time.find_zone(reporting_timezone)
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          a_moment_ago = beginning_of_month - 1.minute # A moment before the provided date
          a_moment_from_now = beginning_of_month + 1.minute # A moment after the provided date

          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: long_ago)
          ltfu_patient = create(:patient, recorded_at: long_ago)

          create(:blood_pressure, patient: not_ltfu_patient, recorded_at: a_moment_ago)
          create(:blood_pressure, patient: ltfu_patient, recorded_at: a_moment_from_now)

          with_reporting_time_zone do
            refresh_views

            expect(described_class.ltfu_as_of(beginning_of_month)).not_to include(not_ltfu_patient)
            expect(described_class.ltfu_as_of(beginning_of_month)).to include(ltfu_patient)

            # Both patients are not LTFU at the end of the month
            expect(described_class.ltfu_as_of(end_of_month)).not_to include(not_ltfu_patient)
            expect(described_class.ltfu_as_of(end_of_month)).not_to include(ltfu_patient)
          end
        end

        it "registration cutoffs for a year ago" do
          # For any provided date in June in the local timezone, the LTFU registration cutoff is the end of June 30 of
          # the previous year in the local timezone
          #
          # Eg. For any date provided in June 2021, the cutoff is the June 30-Jul 1 boundary of 2020

          timezone = Time.find_zone(reporting_timezone)

          under_a_year_ago = timezone.local(2020, 7, 1, 0, 0, 1) # Beginning of July 1 2020 in local timezone
          over_a_year_ago = timezone.local(2020, 6, 30, 23, 59, 59) # End of June 30 2020 in local timezone
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: under_a_year_ago)
          ltfu_patient = create(:patient, recorded_at: over_a_year_ago)

          with_reporting_time_zone do
            refresh_views

            expect(described_class.ltfu_as_of(beginning_of_month)).not_to include(not_ltfu_patient)
            expect(described_class.ltfu_as_of(end_of_month)).not_to include(not_ltfu_patient)

            expect(described_class.ltfu_as_of(beginning_of_month)).to include(ltfu_patient)
            expect(described_class.ltfu_as_of(end_of_month)).to include(ltfu_patient)
          end
        end
      end
    end

    describe ".not_ltfu_as_of" do
      it "excludes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).not_to include(ltfu_patient)
      end

      it "includes patient who is not LTFU because they were registered recently" do
        not_ltfu_patient = Timecop.freeze(6.months.ago) { create(:patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).to include(not_ltfu_patient)
      end

      it "includes patient who is not LTFU because they had a BP recently" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).to include(not_ltfu_patient)
      end

      describe "timezone-specific boundaries" do
        it "bp cutoffs for a year ago" do
          # For any provided date in June in the local timezone, the LTFU BP cutoff is the end of June 30 of the
          # previous year in the local timezone.
          #
          # Eg. For any date provided in June 2021, the cutoff is the June 30-Jul 1 boundary of 2020

          long_ago = 5.years.ago

          # We explicitly set the times in the reporting TZ here, but don't use the block helper because its a hassle w/
          # all the local vars we need
          timezone = Time.find_zone(reporting_timezone)
          under_a_year_ago = timezone.local(2020, 7, 1, 0, 0, 1) # Beginning of July 1 2020 in local timezone
          over_a_year_ago = timezone.local(2020, 6, 30, 23, 59, 59) # End of June 30 2020 in local timezone
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: long_ago)
          ltfu_patient = create(:patient, recorded_at: long_ago)

          create(:blood_pressure, patient: not_ltfu_patient, recorded_at: under_a_year_ago)
          create(:blood_pressure, patient: ltfu_patient, recorded_at: over_a_year_ago)
          refresh_views

          expect(described_class.not_ltfu_as_of(beginning_of_month)).to include(not_ltfu_patient)
          expect(described_class.not_ltfu_as_of(end_of_month)).to include(not_ltfu_patient)

          expect(described_class.not_ltfu_as_of(beginning_of_month)).not_to include(ltfu_patient)
          expect(described_class.not_ltfu_as_of(end_of_month)).not_to include(ltfu_patient)
        end

        it "bp cutoffs for now" do
          # For any provided date in June in the local timezone, the LTFU BP ending cutoff is the time provided

          long_ago = 5.years.ago
          timezone = Time.find_zone(reporting_timezone)
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          a_moment_ago = beginning_of_month - 1.minute # A moment before the provided date
          a_moment_from_now = beginning_of_month + 1.minute # A moment after the provided date

          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: long_ago)
          ltfu_patient = create(:patient, recorded_at: long_ago)

          create(:blood_pressure, patient: not_ltfu_patient, recorded_at: a_moment_ago)
          create(:blood_pressure, patient: ltfu_patient, recorded_at: a_moment_from_now)

          with_reporting_time_zone do
            refresh_views

            expect(described_class.not_ltfu_as_of(beginning_of_month)).to include(not_ltfu_patient)
            expect(described_class.not_ltfu_as_of(beginning_of_month)).not_to include(ltfu_patient)

            # Both patients are not LTFU at the end of the month
            expect(described_class.not_ltfu_as_of(end_of_month)).to include(not_ltfu_patient)
            expect(described_class.not_ltfu_as_of(end_of_month)).to include(ltfu_patient)
          end
        end

        it "registration cutoffs for a year ago" do
          # For any provided date in June in the local timezone, the LTFU registration cutoff is the end of June 30 of
          # the previous year in the local timezone
          #
          # Eg. For any date provided in June 2021, the cutoff is the June 30-Jul 1 boundary of 2020
          timezone = Time.find_zone(reporting_timezone)
          under_a_year_ago = timezone.local(2020, 7, 1, 0, 0, 1) # Beginning of July 1 2020 in local timezone
          over_a_year_ago = timezone.local(2020, 6, 30, 23, 59, 59) # End of June 30 2020 in local timezone
          beginning_of_month = timezone.local(2021, 6, 1, 0, 0, 0) # Beginning of June 1 2021 in local timezone
          end_of_month = timezone.local(2021, 6, 30, 23, 59, 59) # End of June 30 2021 in local timezone

          not_ltfu_patient = create(:patient, recorded_at: under_a_year_ago)
          ltfu_patient = create(:patient, recorded_at: over_a_year_ago)

          with_reporting_time_zone do
            refresh_views

            expect(described_class.not_ltfu_as_of(beginning_of_month)).to include(not_ltfu_patient)
            expect(described_class.not_ltfu_as_of(end_of_month)).to include(not_ltfu_patient)

            expect(described_class.not_ltfu_as_of(beginning_of_month)).not_to include(ltfu_patient)
            expect(described_class.not_ltfu_as_of(end_of_month)).not_to include(ltfu_patient)
          end
        end
      end
    end
  end

  context "Utility methods" do
    let(:patient) { create(:patient) }

    describe "#access_tokens" do
      let(:tokens) { ["token1", "token2"] }
      let(:other_tokens) { ["token3", "token4"] }

      before do
        tokens.each do |token|
          passport = create(:patient_business_identifier, patient: patient)
          create(:passport_authentication, access_token: token, patient_business_identifier: passport)
        end

        other_tokens.each do |token|
          create(:passport_authentication, access_token: token)
        end
      end

      it "returns all access tokens for the patient" do
        expect(patient.access_tokens).to match_array(tokens)
      end
    end

    describe "#risk_priority" do
      it "returns regular priority for patients recently overdue" do
        create(:appointment, scheduled_date: 29.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns high priority for patients overdue with critical bp" do
        create(:blood_pressure, :critical, patient: patient)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns high priority for hypertensive bp patients with medical history risks" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns regular priority for patients overdue with only hypertensive bp" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with only medical risk history" do
        create(:medical_history, :prior_risk_history, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with hypertension" do
        create(:blood_pressure, :hypertensive, patient: patient)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns regular priority for patients overdue with low risk" do
        create(:blood_pressure, :under_control, patient: patient)
        create(:appointment, scheduled_date: 2.years.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end

      it "returns high priority for patients overdue with high blood sugar" do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 300)
        create(:appointment, scheduled_date: 31.days.ago, status: :scheduled, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:HIGH])
      end

      it "returns regular priority for patients overdue with normal blood sugar" do
        create(:blood_sugar, patient: patient, blood_sugar_type: :random, blood_sugar_value: 150)
        create(:appointment, :overdue, patient: patient)

        expect(patient.risk_priority).to eq(Patient::RISK_PRIORITIES[:REGULAR])
      end
    end

    describe "current_age" do
      it "current age is based on date of birth year if present" do
        patient.date_of_birth = Date.parse("1980-01-01")

        expect(patient.current_age).to eq(Date.current.year - 1980)
        patient.save

        expect(Patient.where_current_age("<=", Date.current.year - 1980)).to match_array([patient])
      end

      it "takes into account months for date_of_birth" do
        patient.date_of_birth = Date.parse("June 1st 1960")

        Timecop.freeze("January 1st 2020") do
          expect(patient.current_age).to eq(59)
        end
        Timecop.freeze("June 2nd 2020") do
          expect(patient.current_age).to eq(60)
        end

        patient.save

        Timecop.freeze("January 1st 2020") do
          expect(Patient.where_current_age("=", 59)).to contain_exactly(patient)
        end
        Timecop.freeze("June 2nd 2020") do
          expect(Patient.where_current_age("=", 60)).to contain_exactly(patient)
        end
      end

      it "returns age based on age_updated_at if date of birth is not present" do
        patient = create(:patient, age: 30, age_updated_at: 25.months.ago, date_of_birth: nil)

        expect(patient.current_age).to eq(32)
        expect(Patient.where_current_age("=", 32)).to contain_exactly(patient)
      end
    end

    describe "#latest_phone_number" do
      it "returns the last phone number for the patient" do
        patient = create(:patient)
        _number_1 = create(:patient_phone_number, patient: patient)
        _number_2 = create(:patient_phone_number, patient: patient)
        number_3 = create(:patient_phone_number, patient: patient)

        expect(patient.reload.latest_phone_number).to eq(number_3.number)
      end
    end

    describe "#latest_mobile_number" do
      it "returns the last mobile number for the patient" do
        patient = create(:patient)
        _mobile_number_1 = create(:patient_phone_number, patient: patient, phone_type: "mobile", number: "9999999999")
        mobile_number_2 = create(:patient_phone_number, patient: patient, phone_type: "mobile", number: "1234567890")
        _landline_number = create(:patient_phone_number, phone_type: :landline, patient: patient)
        _invalid_number = create(:patient_phone_number, phone_type: :invalid, patient: patient)

        expect(patient.reload.latest_mobile_number).to eq("+91" + mobile_number_2.number)
      end
    end

    describe "#prescribed_drugs" do
      let!(:date) { Date.parse "01-01-2020" }

      it "returns the prescribed drugs for a patient as of a date" do
        dbl = double("patient.prescribed_as_of")
        allow(patient.prescription_drugs).to receive(:prescribed_as_of).and_return dbl

        expect(patient.prescribed_drugs(date: date)).to be dbl
      end

      it "defaults to current date when no date is passed" do
        expect(patient.prescription_drugs).to receive(:prescribed_as_of).with(Date.current)
        patient.prescribed_drugs
      end
    end
  end

  context "Virtual params" do
    describe "#call_result" do
      it "correctly records successful contact" do
        patient.call_result = "contacted"

        expect(patient.contacted_by_counsellor).to eq(true)
      end

      Patient.could_not_contact_reasons.values.each do |reason|
        it "correctly records could not contact reason: '#{reason}'" do
          patient.call_result = reason

          expect(patient.could_not_contact_reason).to eq(reason)
        end
      end

      it "sets patient status if call indicated they died" do
        patient.call_result = "dead"

        expect(patient.status).to eq("dead")
      end
    end
  end

  context "anonymised data for patients" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the patient" do
        anonymised_data =
          {id: Hashable.hash_uuid(patient.id),
           created_at: patient.created_at,
           registration_date: patient.recorded_at,
           registration_facility_name: patient.registration_facility.name,
           user_id: Hashable.hash_uuid(patient.registration_user.id),
           age: patient.age,
           gender: patient.gender}

        expect(patient.anonymized_data).to eq anonymised_data
      end
    end
  end

  context ".discard_data" do
    it "soft deletes the patient's encounters" do
      patient = create(:patient)
      create_list(:blood_pressure, 2, :with_encounter, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      expect(Encounter.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's observations" do
      patient = create(:patient)
      create_list(:blood_pressure, 2, :with_encounter, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      encounter_ids = Encounter.with_discarded.where(patient: patient).pluck(:id)
      expect(Observation.where(encounter_id: encounter_ids)).to be_empty
    end

    it "soft deletes the patient's blood pressures" do
      patient = create(:patient)
      create_list(:blood_pressure, 2, :with_encounter, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      expect(BloodPressure.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's blood_sugars" do
      patient = create(:patient)
      create_list(:blood_sugar, 2, :with_encounter, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      expect(BloodSugar.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's appointments" do
      patient = create(:patient)
      create_list(:appointment, 2, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      expect(Appointment.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's prescription drugs" do
      patient = create(:patient)
      create_list(:prescription_drug, 2, patient: patient, user: patient.registration_user, facility: patient.registration_facility)

      patient.discard_data
      expect(PrescriptionDrug.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's business identifiers" do
      patient = create(:patient)
      patient.discard_data
      expect(PatientBusinessIdentifier.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's phone numbers" do
      patient = create(:patient)
      patient.discard_data
      expect(PatientPhoneNumber.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's medical history" do
      patient = create(:patient)
      patient.discard_data
      expect(MedicalHistory.where(patient: patient)).to be_empty
    end

    it "soft deletes the patient's address" do
      patient = create(:patient)
      patient.discard_data
      expect(Address.where(id: patient.address_id)).to be_empty
    end

    it "soft deleted the patient's teleconsultations" do
      patient = create(:patient)
      user = patient.registration_user
      create_list(:teleconsultation, 2, patient: patient, requester: user, medical_officer: user, requested_medical_officer: user)
      patient.discard_data

      expect(Teleconsultation.where(patient: patient)).to be_empty
    end
  end
end
