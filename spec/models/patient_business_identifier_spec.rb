require 'rails_helper'

RSpec.describe PatientBusinessIdentifier, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:identifier)}
    it { should validate_presence_of(:identifier_type)}

    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
