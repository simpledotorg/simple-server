require 'rails_helper'

def new_patient_payload(attrs = {})
  payload = Api::Current::PatientPayloadValidator.new(build_patient_payload.deep_merge(attrs))
  payload.validate
  payload
end

describe Api::Current::PatientPayloadValidator, type: :model do
  describe "Validations" do
    it "Validates that either age or date of birth is present" do
      expect(new_patient_payload('address'       => nil,
                                 'phone_numbers' => nil,
                                 'age'           => nil,
                                 'date_of_birth' => Date.today)).to be_valid

      expect(new_patient_payload('address'        => nil,
                                 'phone_numbers'  => nil,
                                 'age'            => rand(18..100),
                                 'age_updated_at' => Time.now,
                                 'date_of_birth'  => nil).valid?).to be true

      expect(new_patient_payload('address'        => nil,
                                 'phone_numbers'  => nil,
                                 'age'            => rand(18..100),
                                 'age_updated_at' => nil,
                                 'date_of_birth'  => nil).valid?).to be false

      expect(new_patient_payload('address'       => nil,
                                 'phone_numbers' => nil,
                                 'age'           => nil,
                                 'date_of_birth' => nil).valid?).to be false
    end

    it 'validates patient date_of_birth is less than today' do
      payload = new_patient_payload('date_of_birth' => 3.days.from_now)
      expect(payload.valid?).to be false
      expect(payload.errors[:date_of_birth]).to be_present
    end

    it "Validates json spec for patient sync request" do
      # required validation
      payload = new_patient_payload('created_at' => nil)
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      payload = new_patient_payload('full_name' => nil)
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      payload = new_patient_payload('address' => { 'created_at' => nil })
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      # non empty validation
      payload = new_patient_payload('full_name' => "")
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      # type and format validation
      payload = new_patient_payload('created_at' => 'foo')
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      payload = new_patient_payload('id' => 'not-a-uuid')
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      payload = new_patient_payload('age' => 'foo')
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      # enum validation
      payload = new_patient_payload('gender' => 'foo')
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present

      payload = new_patient_payload('status' => 'foo')
      expect(payload.valid?).to be false
      expect(payload.errors[:schema]).to be_present
    end
  end
end
