require 'rails_helper'

RSpec.describe Protocol, type: :model do
  describe 'Associations' do
    it { should have_many(:protocol_drugs) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:follow_up_days) }
    it { should validate_numericality_of(:follow_up_days) }
  end
end