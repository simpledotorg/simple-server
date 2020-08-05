require "rails_helper"

RSpec.describe Facility, type: :model do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:blood_pressures).through(:encounters).source(:blood_pressures) }
    it { should have_many(:blood_sugars).through(:encounters).source(:blood_sugars) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:encounters) }
    it { should have_many(:appointments) }

    it { should have_many(:registered_patients).class_name("Patient").with_foreign_key("registration_facility_id") }

    context "patients" do
      it "has distinct patients" do
        facility = create(:facility)
        dm_patient = create(:patient, :diabetes)
        htn_patient = create(:patient)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient)

        expect(facility.patients.count).to eq(2)
      end
    end

    it { should belong_to(:facility_group).optional }
    it { should delegate_method(:follow_ups_by_period).to(:patients).with_prefix(:patient) }
  end

  context ".assigned_patients" do
    let!(:assigned_facilities) { create_list(:facility, 2) }
    let!(:registration_facility) { create(:facility) }
    let!(:patients) do
      [create(:patient, assigned_facility: assigned_facilities.first, registration_facility: registration_facility),
        create(:patient, assigned_facility: assigned_facilities.second, registration_facility: registration_facility)]
    end

    it "returns assigned patients for facilities" do
      expect(Facility.where(id: assigned_facilities).assigned_patients).to match_array patients
    end

    it "ignores registration patients" do
      expect(Facility.where(id: registration_facility).assigned_patients).to be_empty
    end
  end

  describe "Delegates" do
    context "#patient_follow_ups_by_period" do
      it "counts follow_ups across HTN and DM" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 2,
          second_follow_up_date.to_date.beginning_of_month => 2
        }

        expect(facility.patient_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end

    context "#hypertension_follow_ups_by_period" do
      it "counts follow_ups only for hypertensive patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          second_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.hypertension_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end

    context "#diabetes_follow_ups_by_period" do
      it "counts follow_ups only for diabetic patients" do
        registration_date = Time.new(2018, 4, 8)
        first_follow_up_date = registration_date + 1.month
        second_follow_up_date = first_follow_up_date + 1.month

        facility = create(:facility)
        dm_patient = create(:patient, :diabetes, recorded_at: registration_date)
        htn_patient = create(:patient, recorded_at: registration_date)

        create(:blood_sugar, :with_encounter, facility: facility, patient: dm_patient, recorded_at: first_follow_up_date)
        create(:blood_sugar, :with_encounter, facility: facility, patient: htn_patient, recorded_at: first_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: htn_patient, recorded_at: second_follow_up_date)
        create(:blood_pressure, :with_encounter, facility: facility, patient: dm_patient, recorded_at: second_follow_up_date)

        expected_output = {
          first_follow_up_date.to_date.beginning_of_month => 1
        }

        expect(facility.diabetes_follow_ups_by_period(:month).count).to eq(expected_output)
      end
    end
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:district) }
    it { should validate_presence_of(:state) }
    it { should validate_presence_of(:country) }
    it { should validate_numericality_of(:pin) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "#cohort_analytics" do
    it "considers only registered hypertensive patients" do
      facility = create(:facility)

      _non_htn_patients = create_list(:patient, 2, :without_hypertension, registration_facility: facility)
      htn_patients = create_list(:patient, 2, registration_facility: facility)

      expect(CohortAnalyticsQuery).to receive(:new).with(match_array(htn_patients)).and_call_original

      facility.cohort_analytics(:month, 3)
    end
  end

  describe "Search" do
    let!(:facility_1) { create(:facility, name: "HWC Bahadurgarh") }
    let!(:facility_2) { create(:facility, name: "CHC Docomo", slug: "chc-docomo") }
    let!(:facility_3) { create(:facility, name: "CHC Porla Docomo") }

    ["CHC", "DoCoMo", "DOCOMO", "docomo", "cHc", "chc"].each do |term|
      it "matches on case-insensitive searches: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end

    ["Bahadurgarh", "hwc", "HWC Bahadurgarh"].each do |term|
      it "matches on facility name: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array(facility_1)
      end
    end

    it "matches on facility slugs" do
      expect(Facility.search_by_name("chc-docomo")).to match_array(facility_2)
    end

    ["ch", "doco"].each do |term|
      it "partially matches on facility names: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end

    ["\n\n", ""].each do |term|
      it "returns nothing for unmatched searches: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to be_empty
      end
    end

    ["chc\n\n\r", "\b      chc         "].each do |term|
      it "ignores escape characters and whitespace around words: #{term.inspect}" do
        expect(Facility.search_by_name(term)).to match_array([facility_2, facility_3])
      end
    end
  end

  describe ".parse_facilities" do
    let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

    it "parses the facilities" do
      facilities = described_class.parse_facilities(upload_file)
      expect(facilities.first).to include(organization_name: "OrgOne",
                                          facility_group_name: "FGTwo",
                                          name: "Test Facility",
                                          facility_type: "CHC",
                                          district: "Bhatinda",
                                          state: "Punjab",
                                          country: "India",
                                          enable_diabetes_management: "true",
                                          teleconsultation_phone_number: nil,
                                          teleconsultation_isd_code: nil,
                                          import: true)
      expect(facilities.second).to include(organization_name: "OrgOne",
                                           facility_group_name: "FGTwo",
                                           name: "Test Facility 2",
                                           facility_type: "CHC",
                                           district: "Bhatinda",
                                           state: "Punjab",
                                           country: "India",
                                           enable_teleconsultation: "true",
                                           teleconsultation_phone_number: "9999999999",
                                           teleconsultation_isd_code: "91",
                                           import: true)
    end

    it "defaults enable_teleconsultation to false if blank" do
      facilities = described_class.parse_facilities(upload_file)
      expect(facilities.first[:enable_teleconsultation]).to be false
    end

    it "defaults enable_diabetes_management to false if blank" do
      facilities = described_class.parse_facilities(upload_file)
      expect(facilities.second[:enable_diabetes_management]).to be false
    end
  end

  describe "Attribute sanitization" do
    it "squishes and upcases the first letter of the name" do
      facility = FactoryBot.create(:facility, name: " cH name  1  ")
      expect(facility.name).to eq("CH name 1")
    end

    it "squishes and upcases the first letter of the district name" do
      facility = FactoryBot.create(:facility, district: " district name   chennai  ")
      expect(facility.district).to eq("District name chennai")
    end
  end

  describe "Teleconsultation methods" do
    it "returns the first teleconsultation phone number with isd code" do
      facility = FactoryBot.create(:facility,
        enable_teleconsultation: true,
        teleconsultation_phone_numbers: [{isd_code: "+91", phone_number: "00000000"},
          {isd_code: "+91", phone_number: "11111111"}])
      expect(facility.teleconsultation_phone_number_with_isd).to eq("+9100000000")
    end

    it "returns all the teleconsultation phone numbers with isd code" do
      facility = FactoryBot.create(:facility,
        enable_teleconsultation: true,
        teleconsultation_phone_numbers: [{isd_code: "+91", phone_number: "00000000"},
          {isd_code: "+91", phone_number: "11111111"}])
      expect(facility.teleconsultation_phone_numbers_with_isd).to eq([{phone_number: "+9100000000"}, {phone_number: "+9111111111"}])
    end
  end
end
