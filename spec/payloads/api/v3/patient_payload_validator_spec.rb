require "rails_helper"

describe Api::V3::PatientPayloadValidator, type: :model do
  let!(:facility) { create(:facility) }
  let!(:user) { create(:user, registration_facility: facility) }
  let!(:patient) { create(:patient, registration_facility: facility, registration_user: user) }

  def new_patient_payload(attrs = {})
    attrs = attrs.merge(request_user_id: user.id)
    payload = Api::V3::PatientPayloadValidator.new(build_patient_payload(patient).deep_merge(attrs))
    payload.validate
    payload
  end

  describe "Validations" do
    it "Validates that either age or date of birth is present" do
      expect(new_patient_payload("address" => nil,
        "phone_numbers" => nil,
        "age" => nil,
        "date_of_birth" => 20.years.ago)).to be_valid

      expect(new_patient_payload("address" => nil,
        "phone_numbers" => nil,
        "age" => rand(18..100),
        "age_updated_at" => Time.current,
        "date_of_birth" => nil).valid?).to be true

      expect(new_patient_payload("address" => nil,
        "phone_numbers" => nil,
        "age" => rand(18..100),
        "age_updated_at" => nil,
        "date_of_birth" => nil).valid?).to be false

      expect(new_patient_payload("address" => nil,
        "phone_numbers" => nil,
        "age" => nil,
        "date_of_birth" => nil).valid?).to be false
    end

    it "validates patient date_of_birth is less than today" do
      payload = new_patient_payload("date_of_birth" => 3.days.from_now)
      expect(payload.valid?).to be false
      expect(payload.errors[:date_of_birth]).to be_present
    end

    describe "Required validations" do
      it "Validates json spec for patient sync request" do
        payload = new_patient_payload("created_at" => nil)
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
      it "Validates that full_name is required" do
        payload = new_patient_payload("full_name" => nil)
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
      it "Validates that address is required" do
        payload = new_patient_payload("address" => {"created_at" => nil})
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
    end

    describe "Non empty validations" do
      it "Validates that full_name is not empty" do
        payload = new_patient_payload("full_name" => "")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
    end

    describe "type and format validations" do
      it "Validates that created_at is of the right type and format" do
        payload = new_patient_payload("created_at" => "foo")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end

      it "Validates that id is of the right type and format" do
        payload = new_patient_payload("id" => "not-a-uuid")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end

      it "Validates that age is of the right type and format" do
        payload = new_patient_payload("age" => "foo")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
    end

    describe "Enum validations" do
      it "Validates that gender is present in the prescribed enum" do
        payload = new_patient_payload("gender" => "foo")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end

      it "Validates that status is present in the prescribed enum" do
        payload = new_patient_payload("status" => "foo")
        expect(payload.valid?).to be false
        expect(payload.errors[:schema]).to be_present
      end
    end

    describe "Data validations" do
      let!(:valid_facility) { create(:facility, facility_group: facility.facility_group) }
      let!(:invalid_facility) { create(:facility) }

      it "validates that the request user can access the patient's registration facility" do
        valid_payload = new_patient_payload("registration_facility_id" => valid_facility.id)
        invalid_payload = new_patient_payload("registration_facility_id" => invalid_facility.id)

        expect(valid_payload.valid?).to be true
        expect(invalid_payload.valid?).to be false
      end

      it "validates that the request user can access the patient's assigned facility" do
        valid_payload = new_patient_payload("assigned_facility_id" => valid_facility.id)
        invalid_payload = new_patient_payload("assigned_facility_id" => invalid_facility.id)

        expect(valid_payload.valid?).to be true
        expect(invalid_payload.valid?).to be false
      end
    end

    context "when schema validations are disabled" do
      around do |example|
        Flipper.enable(:skip_api_validation)
        example.run
        Flipper.disable(:skip_api_validation)
      end

      it "does not validate schema" do
        validator = new_patient_payload

        expect(validator).not_to receive(:validate_schema)

        validator.validate
      end
    end
  end
end
