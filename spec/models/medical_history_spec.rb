require 'rails_helper'

describe MedicalHistory, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
    it { should validate_inclusion_of(:has_prior_heart_attack).in([true, false]) }
    it { should validate_inclusion_of(:has_prior_stroke).in([true, false]) }
    it { should validate_inclusion_of(:has_chronic_kidney_disease).in([true, false]) }
    it { should validate_inclusion_of(:is_on_treatment_for_hypertension).in([true, false]) }
    it { should validate_presence_of(:device_updated_at) }
  end
end
