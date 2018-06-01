require 'rails_helper'

RSpec.describe BloodPressure, type: :model do
  describe 'Validations' do
    it_behaves_like 'application record'
  end

  describe 'Associations' do
    it { should belong_to(:patient)}
  end
end
