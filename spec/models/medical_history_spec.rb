require 'rails_helper'

describe MedicalHistory, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
    it { should validate_presence_of(:device_updated_at) }
  end
end
