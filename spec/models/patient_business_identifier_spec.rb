require 'rails_helper'

RSpec.describe PatientBusinessIdentifier, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should have_one(:passport_authentication) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:identifier) }
    it { should validate_presence_of(:identifier_type) }

    context 'for bangladesh national IDs' do
      subject { described_class.new(identifier_type: 'bangladesh_national_id') }

      it { should validate_presence_of(:identifier).allow_nil }
    end

    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe '#shortcode' do
    let(:business_identifier) { build(:patient_business_identifier) }

    it 'returns the shortcode for Simple BP passports' do
      business_identifier.identifier_type = :simple_bp_passport
      business_identifier.identifier = '1a3b5c2d-4e68-f79a-098b-cd7e6f54a3b2'

      expect(business_identifier.shortcode).to eq('135-2468')
    end
  end
end
