require 'rails_helper'

describe Patient, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:created_at) }
    it { should validate_presence_of(:updated_at) }
    it { should validate_presence_of(:full_name) }
    it { should validate_inclusion_of(:gender).in_array(Patient::GENDERS) }
    it { should validate_inclusion_of(:status).in_array(Patient::STATUSES) }

    it "Validates that either age_when_created or date of birth is present" do
      patient_with_date_of_birth    = FactoryBot.build(
          :patient,
          age_when_created: nil,
          date_of_birth:    Date.today)
      patient_with_age_when_created = FactoryBot.build(
          :patient,
          age_when_created: rand(18..100),
          date_of_birth:    nil)
      patient_without_age           = FactoryBot.build(
          :patient,
          age_when_created: nil,
          date_of_birth:    nil)

      expect(patient_with_date_of_birth.valid?).to be true
      expect(patient_with_age_when_created.valid?).to be true
      expect(patient_without_age.valid?).to be false
    end
  end

  describe "Associations" do
    it { should belong_to(:address) }
    it { should have_many(:patient_phone_numbers) }
    it { should have_many(:phone_numbers).through(:patient_phone_numbers) }
  end
end