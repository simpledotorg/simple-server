require 'rails_helper'

RSpec.describe FacilityPatient, type: :model do
  describe 'Associations' do
    it { should belong_to(:facility) }
    it { should belong_to(:patient) }
  end
end
